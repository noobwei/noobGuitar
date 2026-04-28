import AVFoundation
import Accelerate
import Combine

// MARK: - Karplus-Strong guitar string synthesis
final class GuitarAudioEngine: ObservableObject {

    // MARK: Public state
    @Published var isRunning = false

    // MARK: Private audio graph
    private let engine      = AVAudioEngine()
    private var sourceNode : AVAudioSourceNode?

    // MARK: Per-string wavetable buffers (one ring-buffer per string)
    private let stringCount = 6
    // Delay-line storage  (max period ~ 44100/80 ≈ 551 samples)
    private var delayLines  : [[Float]] = []
    private var positions   : [Int]     = []
    private var periodSizes : [Int]     = []
    private var amplitudes  : [Float]   = []   // per-string gain (decays naturally via KS)
    private var pluckQueues : [Bool]    = []   // flag: string needs re-trigger
    private var pluckNoise  : [[Float]] = []   // pre-computed excitation noise

    // Thread-safety: audio callback reads these; Swift concurrency not needed —
    // we use a simple spin-safe atomic flag approach via a queue flag array.

    private let sampleRate: Double = 44100
    // Standard guitar open-string MIDI notes: E2 A2 D3 G3 B3 E4
    static let openStringMidi: [Int] = [40, 45, 50, 55, 59, 64]
    static let openStringNames = ["E2","A2","D3","G3","B3","E4"]

    // Capo / fret offset per string (0 = open)
    private var fretOffsets: [Int] = Array(repeating: 0, count: 6)

    // MARK: - Init
    init() {
        setupDelayLines()
        setupAudioEngine()
    }

    // MARK: - Setup
    private func setupDelayLines() {
        delayLines  = Array(repeating: [], count: stringCount)
        positions   = Array(repeating: 0,  count: stringCount)
        periodSizes = Array(repeating: 1,  count: stringCount)
        amplitudes  = Array(repeating: 0,  count: stringCount)
        pluckQueues = Array(repeating: false, count: stringCount)
        pluckNoise  = Array(repeating: [], count: stringCount)

        for i in 0..<stringCount {
            let midi   = Self.openStringMidi[i]
            let period = midiToPeriod(midi)
            delayLines[i]  = Array(repeating: 0, count: period)
            periodSizes[i] = period
        }
    }

    private func midiToPeriod(_ midi: Int) -> Int {
        let freq = 440.0 * pow(2.0, Double(midi - 69) / 12.0)
        return max(2, Int(sampleRate / freq))
    }

    private func setupAudioEngine() {
        let format = AVAudioFormat(
            standardFormatWithSampleRate: sampleRate,
            channels: 1)!

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

    // MARK: - Realtime render (called on audio thread — no allocations)
    private func render(frameCount: Int, ablPointer: UnsafeMutablePointer<AudioBufferList>) {
        let abl = UnsafeMutableAudioBufferListPointer(ablPointer)
        guard let buf = abl[0].mData?.assumingMemoryBound(to: Float.self) else { return }

        for frame in 0..<frameCount {
            var sample: Float = 0

            for s in 0..<stringCount {
                // Re-trigger: fill delay line with noise if flagged
                if pluckQueues[s] {
                    pluckQueues[s] = false
                    let noise = pluckNoise[s]
                    for k in 0..<periodSizes[s] {
                        delayLines[s][k] = noise[k]
                    }
                    positions[s] = 0
                    amplitudes[s] = 1.0
                }

                guard amplitudes[s] > 0.0001 else { continue }

                let period = periodSizes[s]
                let pos    = positions[s]
                let next   = (pos + 1) % period

                // Karplus-Strong: average current and next sample (low-pass)
                let filtered = 0.998 * 0.5 * (delayLines[s][pos] + delayLines[s][next])
                delayLines[s][pos] = filtered
                sample += filtered * amplitudes[s]

                positions[s] = next

                // Amplitude envelope: KS decay is already baked in via the filter,
                // but we track amplitude from the RMS so we can silence the string
                amplitudes[s] *= 0.99997
                if amplitudes[s] < 0.0001 { amplitudes[s] = 0 }
            }

            buf[frame] = sample * 0.18  // mix-down gain
        }
    }

    // MARK: - Public API

    /// Pluck string `index` at fret `fret` (0 = open string).
    func pluck(string: Int, fret: Int = 0) {
        guard string >= 0 && string < stringCount else { return }

        let midi   = Self.openStringMidi[string] + fret
        let period = midiToPeriod(midi)

        // Build excitation noise (off audio thread is fine — we copy atomically via flag)
        var noise = [Float](repeating: 0, count: period)
        for i in 0..<period { noise[i] = Float.random(in: -1...1) }

        // Resize delay line if period changed
        if period != periodSizes[string] {
            delayLines[string] = Array(repeating: 0, count: period)
            periodSizes[string] = period
        }
        pluckNoise[string]  = noise
        positions[string]   = 0
        pluckQueues[string] = true   // audio thread picks this up
        amplitudes[string]  = 1.0
    }

    /// Mute a string immediately.
    func mute(string: Int) {
        guard string >= 0 && string < stringCount else { return }
        amplitudes[string] = 0
        for i in 0..<delayLines[string].count { delayLines[string][i] = 0 }
    }

    /// Strum all 6 strings (low → high) with a small delay between each.
    func strum(frets: [Int], direction: StrumDirection = .downward, delay: TimeInterval = 0.03) {
        let order = direction == .downward ? Array(0..<stringCount) : Array((0..<stringCount).reversed())
        for (i, s) in order.enumerated() {
            let fret = (frets.indices.contains(s)) ? frets[s] : 0
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
