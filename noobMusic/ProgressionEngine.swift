import Foundation
import Combine

// MARK: - Chord Progression Engine
// Manages a fixed-length slot array and advances through it in sync with a BPM timer.
final class ProgressionEngine: ObservableObject {

    // ── Configuration ─────────────────────────────────────────────────
    static let slotCount = 8

    /// Number of metronome beats each chord slot lasts.
    @Published var beatsPerChord: Int = 2  { didSet { restartIfPlaying() } }

    /// Whether to loop back to slot 0 after the last filled slot.
    @Published var loopMode: Bool = true

    // ── State ─────────────────────────────────────────────────────────
    @Published var slots        : [Chord?] = Array(repeating: nil, count: slotCount)
    @Published var currentSlot  : Int      = 0
    @Published var isPlaying    : Bool     = false
    /// Beat counter within the current chord slot (0 …< beatsPerChord)
    @Published var beatInSlot   : Int      = 0
    /// The chord currently being played (nil when stopped or slot is empty)
    @Published var currentChord : Chord?   = nil

    // ── Callbacks ─────────────────────────────────────────────────────
    /// Called on the main thread whenever a chord slot becomes active.
    var onChordChange: ((Chord?) -> Void)?

    // ── Private ───────────────────────────────────────────────────────
    private var timer       : AnyCancellable?
    private var bpm         : Int = 80

    // MARK: - Public API

    func start(bpm: Int) {
        self.bpm = bpm
        guard !isPlaying else { return }
        isPlaying = true
        beatInSlot = 0
        // Fire current slot immediately
        currentChord = slots[currentSlot]
        onChordChange?(currentChord)
        scheduleTimer()
    }

    func stop() {
        timer?.cancel()
        timer = nil
        isPlaying = false
        beatInSlot = 0
        currentChord = nil
    }

    func toggle(bpm: Int) {
        isPlaying ? stop() : start(bpm: bpm)
    }

    func updateBPM(_ newBPM: Int) {
        bpm = newBPM
        if isPlaying { restartIfPlaying() }
    }

    // ── Slot editing ──────────────────────────────────────────────────
    func assign(chord: Chord, toSlot index: Int) {
        guard index < Self.slotCount else { return }
        slots[index] = chord
    }

    func clearSlot(_ index: Int) {
        guard index < Self.slotCount else { return }
        slots[index] = nil
    }

    func clearAll() {
        slots = Array(repeating: nil, count: Self.slotCount)
        stop()
        currentSlot = 0
        currentChord = nil
    }

    // ── Filled slots (for playback range) ────────────────────────────
    var lastFilledIndex: Int? {
        slots.indices.last { slots[$0] != nil }
    }

    // MARK: - Private

    private func scheduleTimer() {
        let interval = 60.0 / Double(bpm)
        timer = Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in self?.tick() }
    }

    private func tick() {
        beatInSlot += 1
        if beatInSlot >= beatsPerChord {
            beatInSlot = 0
            advance()
        }
    }

    private func advance() {
        let limit = (lastFilledIndex ?? 0) + 1   // play up to last filled slot
        var next = currentSlot + 1
        if next >= limit {
            if loopMode {
                next = 0
            } else {
                stop()
                return
            }
        }
        currentSlot = next
        currentChord = slots[currentSlot]
        onChordChange?(currentChord)
    }

    private func restartIfPlaying() {
        guard isPlaying else { return }
        timer?.cancel()
        beatInSlot = 0
        scheduleTimer()
    }
}
