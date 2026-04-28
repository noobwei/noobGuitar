import AVFoundation
import Combine

// MARK: - Simple Metronome (click sound + visual beat)
final class MetronomeEngine: ObservableObject {

    // ── Published state ──────────────────────────────────────────────
    @Published var isPlaying  : Bool = false
    @Published var bpm        : Int  = 80     // 40 – 220
    @Published var beatFlash  : Bool = false  // toggles each beat for visual pulse

    let bpmRange: ClosedRange<Int> = 40...220

    // ── Private ──────────────────────────────────────────────────────
    private var timer       : AnyCancellable?
    private let audioEngine  = AVAudioEngine()
    private let playerNode   = AVAudioPlayerNode()
    private var clickBuffer  : AVAudioPCMBuffer?

    // MARK: - Init
    init() {
        setupAudio()
    }

    // MARK: - Audio setup
    private func setupAudio() {
        let sampleRate: Double = 44100
        let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1)!

        // Build a short "click" — a damped sine burst (~8 ms)
        let clickLength = Int(sampleRate * 0.008)
        guard let buf = AVAudioPCMBuffer(pcmFormat: format,
                                         frameCapacity: AVAudioFrameCount(clickLength)) else { return }
        buf.frameLength = AVAudioFrameCount(clickLength)
        let data = buf.floatChannelData![0]
        for i in 0..<clickLength {
            let t = Double(i) / sampleRate
            let envelope = exp(-t / 0.003)                      // fast decay
            data[i] = Float(envelope * sin(2 * .pi * 1200 * t)) // 1200 Hz tone
        }
        clickBuffer = buf

        audioEngine.attach(playerNode)
        audioEngine.connect(playerNode, to: audioEngine.mainMixerNode, format: format)

        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
        } catch {
            print("MetronomeEngine audio error: \(error)")
        }
    }

    // MARK: - Control
    func start() {
        guard !isPlaying else { return }
        isPlaying = true
        tick()                      // fire immediately on start
        scheduleTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isPlaying = false
        beatFlash = false
    }

    func toggle() { isPlaying ? stop() : start() }

    func updateBPM(_ newBPM: Int) {
        bpm = newBPM.clamped(to: bpmRange)
        if isPlaying {
            timer?.cancel()
            scheduleTimer()
        }
    }

    // MARK: - Internal
    private func scheduleTimer() {
        let interval = 60.0 / Double(bpm)
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        playClick()
        // Flash the beat indicator
        beatFlash = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
            self?.beatFlash = false
        }
    }

    private func playClick() {
        guard let buf = clickBuffer else { return }
        playerNode.scheduleBuffer(buf, completionHandler: nil)
        if !playerNode.isPlaying { playerNode.play() }
    }
}

// MARK: - Clamped helper
extension Comparable {
    func clamped(to range: ClosedRange<Self>) -> Self {
        min(max(self, range.lowerBound), range.upperBound)
    }
}
