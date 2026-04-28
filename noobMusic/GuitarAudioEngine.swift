import AVFoundation
import Accelerate
import Combine

// MARK: - Karplus-Strong guitar string synthesis
final class GuitarAudioEngine: ObservableObject {

    // MARK: Public state
    @Published var isRunning = false

    // MARK: Private audio graph
    private let engine     = AVAudioEngine()
    private var sourceNode: AVAudioSourceNode?

    // MARK: Delay-line constants
    private let stringCount = 6
    private let maxPeriod   = 560          // > E2 period (≈535 samples @ 44 100 Hz)

    // Flat, C-style delay buffer: string s, sample i  →  delayMem[s * maxPeriod + i]
    //
    // Allocated once in init, freed in deinit.  NEVER reallocated or moved.
    // A raw UnsafeMutablePointer has ZERO Swift ARC / COW overhead, so the audio
    // thread and the main thread can safely access different string slots (different
    // base offsets) with no memory corruption.
    private let delayMem: UnsafeMutablePointer<Float>

    // Per-string scalar state (only written from main thread before raising pluckQueues)
    private var positions   = [Int](repeating: 0,     count: 6)
    private var periodSizes = [Int](repeating: 1,     count: 6)
    private var amplitudes  = [Float](repeating: 0,   count: 6)
    /// Written LAST by main thread after noise is committed; polled by audio thread.
    private var pluckQueues = [Bool](repeating: false, count: 6)

    private let sampleRate: Double = 44_100
    static let openStringMidi:  [Int]    = [40, 45, 50, 55, 59, 64]
    static let openStringNames: [String] = ["E2","A2","D3","G3","B3","E4"]

    // MARK: - Init / Deinit
    init() {
        // One-time flat allocation — never resized
        let capacity = 6 * 560
        delayMem = .allocate(capacity: capacity)
        delayMem.initialize(repeating: 0, count: capacity)

        for i in 0..<6 { periodSizes[i] = midiToPeriod(Self.openStringMidi[i]) }
        setupAudioEngine()
    }

    deinit {
        engine.stop()
        delayMem.deinitialize(count: 6 * 560)
        delayMem.deallocate()
    }

    // MARK: - Helpers
    @inline(__always)
    private func base(_ s: Int) -> Int { s * maxPeriod }

    private func midiToPeriod(_ midi: Int) -> Int {
        let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
        return max(2, Int(sampleRate / freq))
    }

    // MARK: - Audio engine setup
    private func setupAudioEngine() {
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        let node = AVAudioSourceNode(format: format) { [weak self] _, _, frameCount, audioBufferList in
            guard let self else { return noErr }
            self.render(frameCount: Int(frameCount), ablPointer: audioBufferList)
            return noErr
        }
        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        engine.mainMixerNode.outputVolume = 1.0

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            try engine.start()
            DispatchQueue.main.async { self.isRunning = true }
        } catch {
            print("AudioEngine start error: \(error)")
        }
    }

    // MARK: - Realtime render  (audio thread — zero allocations, zero ARC)
    private func render(frameCount: Int, ablPointer: UnsafeMutablePointer<AudioBufferList>) {
        let abl = UnsafeMutableAudioBufferListPointer(ablPointer)
        guard let buf = abl[0].mData?.assumingMemoryBound(to: Float.self) else { return }

        for frame in 0..<frameCount {
            var sample: Float = 0

            for s in 0..<stringCount {
                // Noise was written into delayMem by pluck() before this flag was set.
                if pluckQueues[s] {
                    pluckQueues[s] = false
                    positions[s]   = 0
                    amplitudes[s]  = 1.0
                }

                guard amplitudes[s] > 0.0001 else { continue }

                let period = periodSizes[s]
                let pos    = positions[s]
                let next   = (pos + 1) % period
                let b      = base(s)

                // Karplus-Strong low-pass average
                let filtered = 0.998 * 0.5 * (delayMem[b + pos] + delayMem[b + next])
                delayMem[b + pos] = filtered
                sample += filtered * amplitudes[s]

                positions[s]   = next
                amplitudes[s] *= 0.99997
                if amplitudes[s] < 0.0001 { amplitudes[s] = 0 }
            }

            buf[frame] = sample * 0.18   // mix-down gain
        }
    }

    // MARK: - Public API

    /// Pluck string `index` at fret `fret` (0 = open string).
    func pluck(string: Int, fret: Int = 0) {
        guard string >= 0 && string < stringCount else { return }

        let midi   = Self.openStringMidi[string] + fret
        let period = midiToPeriod(midi)
        let b      = base(string)

        // Update period before writing noise so the audio thread (if it somehow
        // wakes up mid-write) never indexes past the allocated region.
        periodSizes[string] = period

        // Write excitation noise directly into the flat buffer — no Swift array,
        // no COW, no ARC.  Audio thread won't touch this string until the flag below.
        for i in 0..<period         { delayMem[b + i] = Float.random(in: -1...1) }
        for i in period..<maxPeriod { delayMem[b + i] = 0 }   // silence tail

        positions[string]   = 0
        amplitudes[string]  = 1.0
        pluckQueues[string] = true   // signal audio thread — written LAST
    }

    /// Mute a string immediately.
    func mute(string: Int) {
        guard string >= 0 && string < stringCount else { return }
        amplitudes[string] = 0
        let b = base(string)
        for i in 0..<maxPeriod { delayMem[b + i] = 0 }
    }

    /// Strum all 6 strings with a small inter-string delay.
    func strum(frets: [Int], direction: StrumDirection = .downward, delay: TimeInterval = 0.03) {
        let order = direction == .downward
            ? Array(0..<stringCount)
            : Array((0..<stringCount).reversed())
        for (i, s) in order.enumerated() {
            let fret = frets.indices.contains(s) ? frets[s] : 0
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(i) * delay) { [weak self] in
                self?.pluck(string: s, fret: fret)
            }
        }
    }

    func stop() {
        engine.stop()
        DispatchQueue.main.async { self.isRunning = false }
    }
}

enum StrumDirection { case downward, upward }
