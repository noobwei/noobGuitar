import SwiftUI
import Combine

// MARK: - Chord category
enum ChordCategory: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case major   = "大调"
    case minor   = "小调"
    case seventh = "七和弦"
    case jazz    = "爵士"
    case other   = "挂留 & 其他"
}

// MARK: - Chord (fret per string, -1 = muted)
struct Chord: Identifiable, Equatable {
    let id       = UUID()
    let name     : String
    let frets    : [Int]        // index 0 = low-E (string 0)
    let emoji    : String
    let category : ChordCategory

    static func == (lhs: Chord, rhs: Chord) -> Bool { lhs.id == rhs.id }
}

extension Chord {
    static let presets: [Chord] = [
        // ── 大调 ──────────────────────────────────────────────────────
        Chord(name:"C",   frets:[-1,3,2,0,1,0],   emoji:"🎵", category:.major),
        Chord(name:"D",   frets:[-1,-1,0,2,3,2],  emoji:"✨", category:.major),
        Chord(name:"E",   frets:[0,2,2,1,0,0],    emoji:"⚡️", category:.major),
        Chord(name:"F",   frets:[1,3,3,2,1,1],    emoji:"🔥", category:.major),
        Chord(name:"G",   frets:[3,2,0,0,0,3],    emoji:"🎶", category:.major),
        Chord(name:"A",   frets:[-1,0,2,2,2,0],   emoji:"🌟", category:.major),
        Chord(name:"B",   frets:[-1,2,4,4,4,2],   emoji:"💫", category:.major),
        Chord(name:"Bb",  frets:[-1,1,3,3,3,1],   emoji:"🎼", category:.major),
        Chord(name:"F#",  frets:[2,4,4,3,2,2],    emoji:"🎸", category:.major),
        Chord(name:"Ab",  frets:[4,6,6,5,4,4],    emoji:"🎵", category:.major),
        Chord(name:"C#",  frets:[-1,4,6,6,6,4],   emoji:"✨", category:.major),
        Chord(name:"Eb",  frets:[-1,6,5,3,4,3],   emoji:"🎼", category:.major),
        // ── 小调 ──────────────────────────────────────────────────────
        Chord(name:"Dm",  frets:[-1,-1,0,2,3,1],  emoji:"🎸", category:.minor),
        Chord(name:"Em",  frets:[0,2,2,0,0,0],    emoji:"🎸", category:.minor),
        Chord(name:"Fm",  frets:[1,3,3,1,1,1],    emoji:"🎼", category:.minor),
        Chord(name:"Gm",  frets:[3,5,5,3,3,3],    emoji:"🎶", category:.minor),
        Chord(name:"Am",  frets:[-1,0,2,2,1,0],   emoji:"🎵", category:.minor),
        Chord(name:"Bm",  frets:[-1,2,4,4,3,2],   emoji:"💫", category:.minor),
        Chord(name:"Cm",  frets:[-1,3,5,5,4,3],   emoji:"🌙", category:.minor),
        Chord(name:"F#m", frets:[2,4,4,2,2,2],    emoji:"🎸", category:.minor),
        Chord(name:"C#m", frets:[-1,4,6,6,5,4],   emoji:"🌙", category:.minor),
        Chord(name:"G#m", frets:[4,6,6,4,4,4],    emoji:"💫", category:.minor),
        Chord(name:"Bbm", frets:[-1,1,3,3,2,1],   emoji:"🎼", category:.minor),
        // ── 七和弦 ────────────────────────────────────────────────────
        Chord(name:"G7",    frets:[3,2,0,0,0,1],   emoji:"7️⃣", category:.seventh),
        Chord(name:"C7",    frets:[-1,3,2,3,1,0],  emoji:"7️⃣", category:.seventh),
        Chord(name:"D7",    frets:[-1,-1,0,2,1,2], emoji:"7️⃣", category:.seventh),
        Chord(name:"E7",    frets:[0,2,0,1,0,0],   emoji:"7️⃣", category:.seventh),
        Chord(name:"A7",    frets:[-1,0,2,0,2,0],  emoji:"7️⃣", category:.seventh),
        Chord(name:"B7",    frets:[-1,2,1,2,0,2],  emoji:"7️⃣", category:.seventh),
        Chord(name:"F7",    frets:[1,3,1,2,1,1],   emoji:"7️⃣", category:.seventh),
        Chord(name:"Cmaj7", frets:[-1,3,2,0,0,0],  emoji:"✨", category:.seventh),
        Chord(name:"Gmaj7", frets:[3,2,0,0,0,2],   emoji:"✨", category:.seventh),
        Chord(name:"Amaj7", frets:[-1,0,2,1,2,0],  emoji:"✨", category:.seventh),
        Chord(name:"Dmaj7", frets:[-1,-1,0,2,2,2], emoji:"✨", category:.seventh),
        Chord(name:"Fmaj7", frets:[1,3,3,2,1,0],   emoji:"✨", category:.seventh),
        Chord(name:"Bmaj7", frets:[-1,2,4,3,4,2],  emoji:"✨", category:.seventh),
        Chord(name:"Em7",   frets:[0,2,2,0,3,0],   emoji:"🎸", category:.seventh),
        Chord(name:"Am7",   frets:[-1,0,2,0,1,0],  emoji:"🎵", category:.seventh),
        Chord(name:"Dm7",   frets:[-1,-1,0,2,1,1], emoji:"💫", category:.seventh),
        Chord(name:"Cm7",   frets:[-1,3,5,3,4,3],  emoji:"🌙", category:.seventh),
        Chord(name:"Fm7",   frets:[1,3,3,1,4,1],   emoji:"🎼", category:.seventh),
        Chord(name:"Gm7",   frets:[3,5,3,3,3,3],   emoji:"🎶", category:.seventh),
        Chord(name:"Bm7",   frets:[-1,2,4,2,3,2],  emoji:"💫", category:.seventh),
        // ── 爵士 ─────────────────────────────────────────────────────
        Chord(name:"Cmaj9",  frets:[-1,3,2,0,3,0],  emoji:"🎷", category:.jazz),
        Chord(name:"Am9",    frets:[-1,0,2,0,1,3],  emoji:"🎷", category:.jazz),
        Chord(name:"Dm9",    frets:[-1,-1,0,2,1,3], emoji:"🎷", category:.jazz),
        Chord(name:"G9",     frets:[3,2,0,2,0,1],   emoji:"🎷", category:.jazz),
        Chord(name:"G13",    frets:[3,2,0,0,0,1],   emoji:"🎺", category:.jazz),
        Chord(name:"C9",     frets:[-1,3,2,3,3,0],  emoji:"🎺", category:.jazz),
        Chord(name:"A9",     frets:[-1,0,2,0,2,2],  emoji:"🎺", category:.jazz),
        Chord(name:"E7#9",   frets:[0,2,0,1,3,0],   emoji:"🎷", category:.jazz),
        Chord(name:"Adim7",  frets:[-1,0,1,2,1,2],  emoji:"🌀", category:.jazz),
        Chord(name:"Bdim",   frets:[-1,2,3,4,3,-1], emoji:"🌀", category:.jazz),
        Chord(name:"Caug",   frets:[-1,3,2,1,1,0],  emoji:"⬆️", category:.jazz),
        Chord(name:"C6",     frets:[-1,3,2,2,1,0],  emoji:"6️⃣", category:.jazz),
        Chord(name:"A6",     frets:[-1,0,2,2,2,2],  emoji:"6️⃣", category:.jazz),
        // ── 挂留 & 其他 ──────────────────────────────────────────────
        Chord(name:"Dsus2",  frets:[-1,-1,0,2,3,0], emoji:"🌊", category:.other),
        Chord(name:"Dsus4",  frets:[-1,-1,0,2,3,3], emoji:"🌊", category:.other),
        Chord(name:"Asus2",  frets:[-1,0,2,2,0,0],  emoji:"🌊", category:.other),
        Chord(name:"Asus4",  frets:[-1,0,2,2,3,0],  emoji:"🌊", category:.other),
        Chord(name:"Esus4",  frets:[0,2,2,2,0,0],   emoji:"🌊", category:.other),
        Chord(name:"Gsus2",  frets:[3,2,0,2,3,3],   emoji:"🌊", category:.other),
        Chord(name:"Bsus4",  frets:[-1,2,4,4,5,2],  emoji:"🌊", category:.other),
        Chord(name:"Csus2",  frets:[-1,3,3,0,1,0],  emoji:"🌊", category:.other),
        Chord(name:"Cadd9",  frets:[-1,3,2,0,3,0],  emoji:"➕", category:.other),
        Chord(name:"Gadd9",  frets:[3,2,0,2,0,3],   emoji:"➕", category:.other),
        Chord(name:"Dadd9",  frets:[-1,-1,0,2,3,0], emoji:"➕", category:.other),
        Chord(name:"E5",     frets:[0,2,2,-1,-1,-1], emoji:"💪", category:.other),
        Chord(name:"A5",     frets:[-1,0,2,2,-1,-1], emoji:"💪", category:.other),
        Chord(name:"D5",     frets:[-1,-1,0,2,3,-1], emoji:"💪", category:.other),
        Chord(name:"G5",     frets:[3,5,5,-1,-1,-1], emoji:"💪", category:.other),
        Chord(name:"F5",     frets:[1,3,3,-1,-1,-1], emoji:"💪", category:.other),
        Chord(name:"C5",     frets:[-1,3,5,5,-1,-1], emoji:"💪", category:.other),
    ]

    static func presets(for category: ChordCategory) -> [Chord] {
        presets.filter { $0.category == category }
    }
}

// MARK: - Chord Recognizer
// 根据当前各弦音名（pitch class），在常用和弦模板库中寻找最佳匹配
struct ChordRecognizer {
    static let noteNames = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]

    // (和弦后缀, 从根音开始的音程集合)  —— 更长的模板优先（更精确）
    static let templates: [(String, [Int])] = [
        ("maj9",  [0,4,7,11,2]),
        ("m9",    [0,3,7,10,2]),
        ("9",     [0,4,7,10,2]),
        ("13",    [0,4,7,10,2,9]),
        ("maj7",  [0,4,7,11]),
        ("m7",    [0,3,7,10]),
        ("7",     [0,4,7,10]),
        ("m7b5",  [0,3,6,10]),
        ("dim7",  [0,3,6,9]),
        ("add9",  [0,2,4,7]),
        ("6",     [0,4,7,9]),
        ("m6",    [0,3,7,9]),
        ("7#9",   [0,4,7,10,3]),
        ("aug",   [0,4,8]),
        ("",      [0,4,7]),
        ("m",     [0,3,7]),
        ("dim",   [0,3,6]),
        ("sus2",  [0,2,7]),
        ("sus4",  [0,5,7]),
        ("5",     [0,7]),
    ]

    /// 返回识别到的和弦名，如 "Em"，找不到时返回 nil
    static func recognize(fretPositions: [Int]) -> String? {
        var pitchClasses = Set<Int>()
        for (s, fret) in fretPositions.enumerated() where fret >= 0 {
            let midi = GuitarAudioEngine.openStringMidi[s] + fret
            pitchClasses.insert(midi % 12)
        }
        guard pitchClasses.count >= 2 else { return nil }

        var bestName  : String? = nil
        var bestScore = 0

        for root in 0..<12 {
            for (suffix, intervals) in templates {
                let templateSet = Set(intervals.map { (root + $0) % 12 })
                // 模板所有音必须都在弹奏的音里
                if templateSet.isSubset(of: pitchClasses) {
                    let score = templateSet.count
                    if score > bestScore {
                        bestScore = score
                        bestName  = noteNames[root] + suffix
                    }
                }
            }
        }
        return bestName
    }
}

// MARK: - Note name helpers
extension GuitarAudioEngine {
    static func noteLetter(string: Int, fret: Int) -> String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let midi = openStringMidi[string] + max(0, fret)
        return names[midi % 12]
    }

    static func noteNameFull(string: Int, fret: Int) -> String {
        let names = ["C","C#","D","D#","E","F","F#","G","G#","A","A#","B"]
        let midi = openStringMidi[string] + max(0, fret)
        let octave = midi / 12 - 1
        return "\(names[midi % 12])\(octave)"
    }
}

// MARK: - Strum speed options
struct StrumSpeed: Identifiable {
    let id    = UUID()
    let label : String
    let delay : TimeInterval
}

extension StrumSpeed {
    static let options: [StrumSpeed] = [
        StrumSpeed(label: "慢",  delay: 0.08),
        StrumSpeed(label: "中",  delay: 0.035),
        StrumSpeed(label: "快",  delay: 0.015),
        StrumSpeed(label: "极快", delay: 0.003),
    ]
}

// MARK: - App-level ViewModel
final class GuitarViewModel: ObservableObject {
    @Published var selectedChord   : Chord? = nil
    @Published var fretPosition    : [Int]  = Array(repeating: 0, count: 6)

    // 单弦信息
    @Published var lastNote        : String = ""
    @Published var lastNoteLetter  : String = ""
    @Published var lastNoteString  : Int    = -1
    @Published var lastNoteFret    : Int    = 0

    // 速度（索引对应 StrumSpeed.options）
    @Published var strumSpeedIndex : Int    = 1   // 默认"中"

    // 变调夹（Capo）：0 = 不加 capo，1-7 = 加在对应品格
    @Published var capoFret        : Int    = 0

    var strumDelay: TimeInterval { StrumSpeed.options[strumSpeedIndex].delay }

    // 和弦识别（实时计算，考虑 capo 偏移）
    var detectedChord: String? {
        let shifted = fretPosition.map { $0 >= 0 ? $0 + capoFret : $0 }
        return ChordRecognizer.recognize(fretPositions: shifted)
    }

    let engine = GuitarAudioEngine()

    // MARK: - Actions
    func playChord(_ chord: Chord, direction: StrumDirection = .downward) {
        selectedChord = chord
        fretPosition  = chord.frets
        for (i, f) in chord.frets.enumerated() where f < 0 { engine.mute(string: i) }
        // Apply capo offset when computing actual pitch
        let playable = chord.frets.map { $0 >= 0 ? max(0, $0) + capoFret : 0 }
        engine.strum(frets: playable, direction: direction, delay: strumDelay)
        lastNote = ""
    }

    func pluckString(_ string: Int, fret: Int) {
        let f = max(0, fret) + capoFret   // capo raises the pitch
        engine.pluck(string: string, fret: f)
        lastNote       = GuitarAudioEngine.noteNameFull(string: string, fret: f)
        lastNoteLetter = GuitarAudioEngine.noteLetter(string: string, fret: f)
        lastNoteString = string
        lastNoteFret   = f
        selectedChord  = nil
    }

    func muteAll() {
        for i in 0..<6 { engine.mute(string: i) }
        fretPosition = Array(repeating: 0, count: 6)
        selectedChord = nil
        lastNote = ""
    }
}

enum StrumMode { case auto, manual }
