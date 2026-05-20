import AVFoundation
import Accelerate
import Combine
import SwiftUI
import SwiftUI

// MARK: - Mic Listener — listens to microphone and detects chord being played
// Requires NSMicrophoneUsageDescription in Info.plist
final class MicListenerEngine: ObservableObject {

    // ── Published state ──────────────────────────────────────────────
    @Published var isListening   : Bool    = false
    @Published var matchScore    : Double  = 0     // 0.0 – 1.0
    @Published var detectedNote  : String  = ""    // dominant pitch letter, e.g. "E"
    @Published var feedbackColor : Color   = .gray
    /// nil = no target set
    var targetChord: Chord? = nil
    var capoFret: Int = 0

    // ── Private audio graph ──────────────────────────────────────────
    private let engine       = AVAudioEngine()
    private let fftSize      = 4096
    private let sampleRate   : Double = 44100
    private var window       : [Float] = []
    private var fftSetup     : vDSP_DFT_Setup?
    private var inputBuffer  : [Float] = []

    // ── Note name table ──────────────────────────────────────────────
    private let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    // MARK: - Setup
    init() {
        window = Self.makeHannWindow(size: fftSize)
        fftSetup = vDSP_DFT_zop_CreateSetup(nil,
                                             vDSP_Length(fftSize),
                                             vDSP_DFT_Direction.FORWARD)
        inputBuffer = [Float](repeating: 0, count: fftSize)
    }

    deinit {
        if let s = fftSetup { vDSP_DFT_DestroySetup(s) }
    }

    // MARK: - Permission & Start
    func requestPermissionAndStart() {
        AVAudioApplication.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                if granted {
                    self?.startListening()
                } else {
                    self?.isListening = false
                }
            }
        }
    }

    private func startListening() {
        guard !isListening else { return }

        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord,
                                    mode: .measurement,
                                    options: [.defaultToSpeaker, .mixWithOthers])
            try session.setActive(true)

            let inputNode = engine.inputNode
            let format    = inputNode.outputFormat(forBus: 0)

            inputNode.installTap(onBus: 0,
                                 bufferSize: AVAudioFrameCount(fftSize),
                                 format: format) { [weak self] buffer, _ in
                self?.process(buffer: buffer)
            }

            try engine.start()
            DispatchQueue.main.async { self.isListening = true }
        } catch {
            print("MicListenerEngine start error: \(error)")
        }
    }

    func stopListening() {
        guard isListening else { return }
        engine.inputNode.removeTap(onBus: 0)
        engine.stop()
        do { try AVAudioSession.sharedInstance().setCategory(.playback, options: []) } catch {}
        DispatchQueue.main.async {
            self.isListening  = false
            self.matchScore   = 0
            self.detectedNote = ""
            self.feedbackColor = .gray
        }
    }

    func toggle() {
        isListening ? stopListening() : requestPermissionAndStart()
    }

    // MARK: - FFT Processing (audio callback thread)
    private func process(buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }

        // Fill inputBuffer (rolling window)
        let src = channelData[0]
        let copyLen = min(frameLength, fftSize)
        let keepLen = fftSize - copyLen
        if keepLen > 0 {
            inputBuffer.removeFirst(copyLen)
            inputBuffer.append(contentsOf: (0..<copyLen).map { src[$0] })
        } else {
            inputBuffer = (0..<fftSize).map { src[min($0, frameLength-1)] }
        }

        // Apply Hann window
        var windowed = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(inputBuffer, 1, window, 1, &windowed, 1, vDSP_Length(fftSize))

        // Compute RMS — skip analysis if signal is too quiet (avoid false detections)
        var rms: Float = 0
        vDSP_rmsqv(windowed, 1, &rms, vDSP_Length(fftSize))
        guard rms > 0.002 else {
            DispatchQueue.main.async {
                self.matchScore   = 0
                self.detectedNote = ""
                self.feedbackColor = .gray
            }
            return
        }

        // FFT via vDSP_DFT
        var realIn  = windowed
        var imagIn  = [Float](repeating: 0, count: fftSize)
        var realOut = [Float](repeating: 0, count: fftSize)
        var imagOut = [Float](repeating: 0, count: fftSize)

        guard let setup = fftSetup else { return }
        vDSP_DFT_Execute(setup, &realIn, &imagIn, &realOut, &imagOut)

        // Magnitude spectrum (only first half)
        let half = fftSize / 2
        var mag  = [Float](repeating: 0, count: half)
        for i in 0..<half {
            mag[i] = sqrt(realOut[i] * realOut[i] + imagOut[i] * imagOut[i])
        }

        // Collect dominant pitch classes using harmonic product spectrum (HPS, 3 harmonics)
        let hpsOrder = 3
        var hps = mag
        for h in 2...hpsOrder {
            for i in 0..<half {
                let j = i * h
                if j < half {
                    hps[i] *= mag[j]
                } else {
                    hps[i] = 0
                }
            }
        }

        // Find top-5 peaks in 80–1200 Hz range
        let lowBin  = Int(80.0  * Double(fftSize) / sampleRate)
        let highBin = Int(1200.0 * Double(fftSize) / sampleRate)
        var pitchClasses = Set<Int>()

        for _ in 0..<5 {
            var peak: Float = 0
            var peakIdx = lowBin
            // manual argmax in range
            for i in lowBin..<min(highBin, half) {
                if hps[i] > peak { peak = hps[i]; peakIdx = i }
            }
            guard peak > 0 else { break }
            let freq = Double(peakIdx) * sampleRate / Double(fftSize)
            if let midi = freqToMidi(freq) {
                pitchClasses.insert(midi % 12)
            }
            // zero out around peak to find next
            let spread  = max(1, Int(50.0 * Double(fftSize) / sampleRate))
            let zeroLo  = max(lowBin, peakIdx - spread)
            let zeroHi  = min(highBin - 1, peakIdx + spread)
            if zeroLo <= zeroHi {
                for j in zeroLo...zeroHi { hps[j] = 0 }
            }
        }

        // Dominant single note (highest magnitude non-HPS peak)
        var singlePeakBin = lowBin
        var singlePeakVal: Float = 0
        for i in lowBin..<min(highBin, half) {
            if mag[i] > singlePeakVal { singlePeakVal = mag[i]; singlePeakBin = i }
        }
        let dominantFreq  = Double(singlePeakBin) * sampleRate / Double(fftSize)
        let dominantNote  = freqToMidi(dominantFreq).map { noteNames[$0 % 12] } ?? ""

        // Score against target chord
        let score = scoreMatch(detected: pitchClasses)

        DispatchQueue.main.async {
            self.detectedNote  = dominantNote
            self.matchScore    = score
            self.feedbackColor = Self.colorForScore(score)
        }
    }

    // MARK: - Scoring
    private func scoreMatch(detected: Set<Int>) -> Double {
        guard let chord = targetChord else { return 0 }
        // Compute expected pitch classes from chord's frets
        var expected = Set<Int>()
        for (s, fret) in chord.frets.enumerated() where fret >= 0 {
            let midi = GuitarAudioEngine.openStringMidi[s] + fret + capoFret
            expected.insert(midi % 12)
        }
        guard !expected.isEmpty, !detected.isEmpty else { return 0 }
        let intersection = expected.intersection(detected).count
        // Jaccard-like score weighted toward expected coverage
        let precision = Double(intersection) / Double(detected.count)
        let recall    = Double(intersection) / Double(expected.count)
        guard precision + recall > 0 else { return 0 }
        return 2 * precision * recall / (precision + recall)   // F1
    }

    // MARK: - Helpers
    private func freqToMidi(_ freq: Double) -> Int? {
        guard freq > 20 else { return nil }
        let midi = 69.0 + 12.0 * log2(freq / 440.0)
        let rounded = Int(midi.rounded())
        guard rounded >= 0 && rounded <= 127 else { return nil }
        return rounded
    }

    static func colorForScore(_ score: Double) -> Color {
        if score > 0.75 { return Color(red: 0.2, green: 0.85, blue: 0.4) }   // green
        if score > 0.45 { return Color(red: 1.0, green: 0.75, blue: 0.1) }   // yellow
        if score > 0.1  { return Color(red: 1.0, green: 0.35, blue: 0.2) }   // red-orange
        return .gray
    }

    static func makeHannWindow(size: Int) -> [Float] {
        var w = [Float](repeating: 0, count: size)
        let N = Float(size - 1)
        for i in 0..<size {
            w[i] = 0.5 * (1 - cos(2 * Float.pi * Float(i) / N))
        }
        return w
    }
}
