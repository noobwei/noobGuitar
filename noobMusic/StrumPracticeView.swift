import SwiftUI

// MARK: - Practice Mode
enum PracticeMode: String, CaseIterable {
    case single      = "单和弦"
    case progression = "和弦进行"
}

// MARK: - Guitar Body Shape (Bézier silhouette)
private struct GuitarBodyShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var path = Path()

        // Lower bout (bigger half)
        let lbCY = h * 0.62
        let lbR  = w * 0.48
        // Upper bout (smaller half)
        let ubCY = h * 0.32
        let ubR  = w * 0.36
        // Waist
        let waistY = h * 0.50
        let waistX = w * 0.22

        path.move(to: CGPoint(x: w * 0.5, y: h * 0.05))   // top center (neck join)

        // Right side — upper bout → waist → lower bout
        path.addCurve(
            to: CGPoint(x: w * 0.5 + lbR * 0.88, y: lbCY),
            control1: CGPoint(x: w * 0.5 + ubR, y: ubCY),
            control2: CGPoint(x: w * 0.5 + waistX, y: waistY)
        )
        // Lower bout right arc
        path.addArc(center: CGPoint(x: w * 0.5, y: lbCY),
                    radius: lbR,
                    startAngle: .degrees(0),
                    endAngle: .degrees(180),
                    clockwise: true)

        // Left side — lower bout → waist → upper bout
        path.addCurve(
            to: CGPoint(x: w * 0.5, y: h * 0.05),
            control1: CGPoint(x: w * 0.5 - waistX, y: waistY),
            control2: CGPoint(x: w * 0.5 - ubR,    y: ubCY)
        )
        path.closeSubpath()
        return path
    }
}

// MARK: - Sound hole
private struct SoundholeShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.addEllipse(in: rect)
        return p
    }
}

// MARK: - Strum Pick shape
private struct PickShape: Shape {
    func path(in rect: CGRect) -> Path {
        let w = rect.width, h = rect.height
        var p = Path()
        p.move(to: CGPoint(x: w * 0.5, y: 0))
        p.addCurve(to: CGPoint(x: w, y: h * 0.45),
                   control1: CGPoint(x: w * 0.95, y: 0),
                   control2: CGPoint(x: w, y: h * 0.20))
        p.addCurve(to: CGPoint(x: w * 0.5, y: h),
                   control1: CGPoint(x: w, y: h * 0.78),
                   control2: CGPoint(x: w * 0.75, y: h))
        p.addCurve(to: CGPoint(x: 0, y: h * 0.45),
                   control1: CGPoint(x: w * 0.25, y: h),
                   control2: CGPoint(x: 0, y: h * 0.78))
        p.addCurve(to: CGPoint(x: w * 0.5, y: 0),
                   control1: CGPoint(x: 0, y: h * 0.20),
                   control2: CGPoint(x: w * 0.05, y: 0))
        p.closeSubpath()
        return p
    }
}

// MARK: - Guitar Pendulum View
struct GuitarPendulumView: View {
    let accentColor  : Color
    let swingAngle   : Double   // degrees, ± swing
    let beatFlash    : Bool
    let strumDir     : StrumDirection

    private let bodyW: CGFloat = 120
    private let bodyH: CGFloat = 150
    private let neckH: CGFloat = 110

    var body: some View {
        ZStack(alignment: .top) {
            // The whole guitar rotates around the tuning-peg end (top)
            VStack(spacing: 0) {
                // ── Headstock ──
                RoundedRectangle(cornerRadius: 5)
                    .fill(Color(red: 0.28, green: 0.16, blue: 0.06))
                    .frame(width: 20, height: 22)
                    .overlay(
                        RoundedRectangle(cornerRadius: 5)
                            .stroke(Color(red: 0.55, green: 0.38, blue: 0.18), lineWidth: 1)
                    )

                // ── Neck ──
                ZStack {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(red: 0.38, green: 0.22, blue: 0.08))
                        .frame(width: 18, height: neckH)

                    // Fret lines on neck
                    ForEach(1...5, id: \.self) { i in
                        Rectangle()
                            .fill(Color(red: 0.80, green: 0.73, blue: 0.48).opacity(0.7))
                            .frame(width: 18, height: 1)
                            .offset(y: CGFloat(i) * neckH / 6 - neckH / 2)
                    }

                    // Strings on neck
                    ForEach(0..<6, id: \.self) { s in
                        let xOff = (CGFloat(s) - 2.5) * 2.2
                        Rectangle()
                            .fill(Color(red: 0.80, green: 0.72, blue: 0.55).opacity(0.5))
                            .frame(width: 0.8, height: neckH)
                            .offset(x: xOff)
                    }
                }

                // ── Body ──
                ZStack {
                    GuitarBodyShape()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.58, green: 0.32, blue: 0.10),
                                    Color(red: 0.38, green: 0.20, blue: 0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: bodyW, height: bodyH)
                        .shadow(color: .black.opacity(0.45), radius: 10, x: 0, y: 6)
                        .overlay(
                            GuitarBodyShape()
                                .stroke(Color(red: 0.72, green: 0.48, blue: 0.22).opacity(0.6), lineWidth: 2)
                        )

                    // Sound hole
                    Circle()
                        .fill(Color.black.opacity(0.70))
                        .frame(width: bodyW * 0.32, height: bodyW * 0.32)
                        .offset(y: -bodyH * 0.05)
                        .overlay(
                            Circle()
                                .stroke(Color(red: 0.72, green: 0.52, blue: 0.22).opacity(0.5), lineWidth: 1.5)
                                .frame(width: bodyW * 0.32, height: bodyW * 0.32)
                                .offset(y: -bodyH * 0.05)
                        )

                    // Strings over body
                    ForEach(0..<6, id: \.self) { s in
                        let xOff = (CGFloat(s) - 2.5) * 2.2
                        Rectangle()
                            .fill(Color(red: 0.82, green: 0.74, blue: 0.56).opacity(0.65))
                            .frame(width: CGFloat(0.8 + Double(s) * 0.22), height: bodyH * 0.55)
                            .offset(x: xOff, y: -bodyH * 0.10)
                    }

                    // Pick indicator at strum zone
                    if beatFlash {
                        PickShape()
                            .fill(accentColor.opacity(0.90))
                            .frame(width: 18, height: 22)
                            .shadow(color: accentColor.opacity(0.8), radius: 8)
                            .offset(x: strumDir == .downward ? 18 : -18,
                                    y: -bodyH * 0.05)
                            .transition(.opacity)
                    }
                }
                .frame(width: bodyW, height: bodyH)
            }
        }
        .rotationEffect(
            .degrees(swingAngle),
            anchor: UnitPoint(x: 0.5, y: 0)   // rotate around the headstock top
        )
    }
}

// MARK: - Beat Dot Strip
private struct BeatDotStrip: View {
    let totalBeats    : Int
    let currentBeat   : Int   // 0-indexed
    let isPlaying     : Bool
    let accentColor   : Color

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0..<totalBeats, id: \.self) { i in
                Circle()
                    .fill(isPlaying && i == currentBeat
                          ? accentColor
                          : Color.white.opacity(0.15))
                    .frame(width: 10, height: 10)
                    .shadow(color: isPlaying && i == currentBeat
                            ? accentColor.opacity(0.8) : .clear,
                            radius: 5)
                    .animation(.easeOut(duration: 0.05), value: currentBeat)
            }
        }
    }
}

// MARK: - Chord Mini Diagram (Canvas)
private struct ChordMiniCard: View {
    let chord       : Chord
    let isActive    : Bool
    let accentColor : Color
    let action      : () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Text(chord.emoji).font(.system(size: 14))
                Text(chord.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isActive ? accentColor : .white)

                // Mini fret dots
                HStack(spacing: 2) {
                    ForEach(0..<6, id: \.self) { s in
                        let f = chord.frets[s]
                        ZStack {
                            Circle()
                                .fill(f < 0 ? Color.red.opacity(0.35) : Color.white.opacity(0.12))
                                .frame(width: 9, height: 9)
                            if f > 0 {
                                Text("\(f)")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundColor(accentColor)
                            } else if f < 0 {
                                Text("✕")
                                    .font(.system(size: 5, weight: .bold))
                                    .foregroundColor(.red.opacity(0.7))
                            }
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isActive ? accentColor.opacity(0.22) : Color.white.opacity(0.07))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isActive ? accentColor.opacity(0.7) : Color.clear, lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - StrumPracticeView
struct StrumPracticeView: View {

    // ── Injected engines ─────────────────────────────────────────────
    @ObservedObject var vm          : GuitarViewModel
    @ObservedObject var metronome   : MetronomeEngine
    @ObservedObject var progression : ProgressionEngine
    @ObservedObject var themeEngine : ThemeEngine

    // ── Dismiss ───────────────────────────────────────────────────────
    @Environment(\.dismiss) private var dismiss

    // ── Local state ───────────────────────────────────────────────────
    @State private var practiceMode      : PracticeMode  = .single
    @State private var selectedSingle    : Chord?        = nil
    @State private var chordCategory     : ChordCategory = .major
    @State private var isPlaying         : Bool          = false
    @State private var swingAngle        : Double        = 0
    @State private var lastSwingRight    : Bool          = true

    // Beat counter for the dot strip (resets when BPM changes)
    @State private var localBeat         : Int           = 0
    @State private var beatCount         : Int           = 4   // visual beats per bar

    // Progression slot assignment
    @State private var assigningSlot     : Int?          = nil

    private let palette = SurfacePalette()
    private var theme: AppTheme { themeEngine.current }

    // The chord that should be displayed / played
    private var activeChord: Chord? {
        practiceMode == .single ? selectedSingle : progression.currentChord
    }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // ── Background ────────────────────────────────────────
                LinearGradient(
                    colors: [palette.backgroundTop,
                             palette.backgroundBottom],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if geo.size.width > geo.size.height {
                    landscapeBody(geo: geo)
                } else {
                    portraitBody(geo: geo)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .preferredColorScheme(.light)
        .ignoresSafeArea(edges: .bottom)
        // Drive swing animation on every beat
        .onChange(of: metronome.beatFlash) { _, flash in
            guard isPlaying, flash else { return }
            swingToNext()
            advanceLocalBeat()
        }
        .onDisappear {
            stopPractice()
        }
    }

    // MARK: - Portrait layout
    private func portraitBody(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            navBar

            Spacer(minLength: 0)

            // ── Guitar pendulum ──
            GuitarPendulumView(
                accentColor: theme.accent,
                swingAngle: swingAngle,
                beatFlash: metronome.beatFlash && isPlaying,
                strumDir: lastSwingRight ? .downward : .upward
            )
            .frame(height: min(geo.size.height * 0.38, 320))
            .padding(.top, 8)

            // Current chord name + beat dots
            chordDisplayRow
                .padding(.top, 12)

            // ── Controls ──
            metronomeCompactPanel
                .padding(.horizontal, 18)
                .padding(.top, 16)

            // ── Mode picker + chord selector ──
            modePicker
                .padding(.horizontal, 18)
                .padding(.top, 14)

            chordPickerSection(width: geo.size.width - 36)
                .padding(.horizontal, 18)
                .padding(.top, 8)

            Spacer(minLength: 8)

            // ── Big play/stop button ──
            startStopButton
                .padding(.bottom, 28)
        }
    }

    // MARK: - Landscape layout
    private func landscapeBody(geo: GeometryProxy) -> some View {
        let leftW  = geo.size.width * 0.42
        let rightW = geo.size.width - leftW - 28

        return VStack(spacing: 0) {
            navBar.padding(.bottom, 4)

            HStack(alignment: .top, spacing: 12) {
                // Left: guitar + beat strip + play button
                VStack(spacing: 10) {
                    GuitarPendulumView(
                        accentColor: theme.accent,
                        swingAngle: swingAngle,
                        beatFlash: metronome.beatFlash && isPlaying,
                        strumDir: lastSwingRight ? .downward : .upward
                    )
                    .frame(height: geo.size.height * 0.55)

                    chordDisplayRow
                    startStopButton
                }
                .frame(width: leftW)
                .padding(.leading, 12)

                // Right: mode picker + controls + chord selector
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 10) {
                        modePicker
                        metronomeCompactPanel
                        chordPickerSection(width: rightW - 8)
                    }
                    .padding(.bottom, 16)
                }
                .frame(width: rightW)
                .padding(.trailing, 16)
            }
        }
    }

    // MARK: - Nav bar
    private var navBar: some View {
        HStack {
            Button {
                stopPractice()
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                    Text("返回")
                        .font(.system(size: 15, weight: .semibold))
                }
                .appBackButtonStyle()
            }

            Spacer()

            Text("扫弦练习")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            Spacer()

            // Placeholder to center the title
            Color.clear.frame(width: 70, height: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
    }

    // MARK: - Chord + beat display
    private var chordDisplayRow: some View {
        VStack(spacing: 6) {
            // Chord name
            if let chord = activeChord {
                HStack(spacing: 6) {
                    Text(chord.emoji)
                        .font(.system(size: 20))
                    Text(chord.name)
                        .font(.system(size: 36, weight: .black, design: .rounded))
                        .foregroundColor(theme.accent)
                        .shadow(color: theme.glow.opacity(0.5), radius: 10)
                }
                .transition(.scale.combined(with: .opacity))
                .animation(.spring(response: 0.3), value: chord.id)
            } else {
                Text("选择和弦开始")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(palette.muted)
            }

            // Beat dots
            BeatDotStrip(
                totalBeats: beatCount,
                currentBeat: localBeat,
                isPlaying: isPlaying,
                accentColor: theme.accent
            )
        }
    }

    // MARK: - Metronome compact panel
    private var metronomeCompactPanel: some View {
        HStack(spacing: 14) {
            // Beat flash indicator
            Circle()
                .fill(metronome.beatFlash && isPlaying ? theme.accent : palette.softFill)
                .frame(width: 32, height: 32)
                .shadow(color: metronome.beatFlash && isPlaying ? theme.glow.opacity(0.7) : .clear, radius: 8)
                .animation(.easeOut(duration: 0.05), value: metronome.beatFlash)

            VStack(spacing: 2) {
                Text("\(metronome.bpm) BPM")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(palette.title)

                Slider(
                    value: Binding(
                        get: { Double(metronome.bpm) },
                        set: { metronome.updateBPM(Int($0)) }
                    ),
                    in: Double(metronome.bpmRange.lowerBound)...Double(metronome.bpmRange.upperBound),
                    step: 1
                )
                .tint(theme.accent)
            }
        }
        .padding(12)
        .appCardStyle(cornerRadius: 14)
    }

    // MARK: - Mode picker
    private var modePicker: some View {
        HStack(spacing: 0) {
            ForEach(PracticeMode.allCases, id: \.rawValue) { mode in
                Button {
                    withAnimation(.spring(response: 0.25)) {
                        practiceMode = mode
                        if isPlaying { stopPractice() }
                    }
                } label: {
                        Text(mode.rawValue)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(practiceMode == mode ? .black : palette.body)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            practiceMode == mode ? theme.accent : Color.clear
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(Capsule())
        .overlay(Capsule().stroke(theme.accent.opacity(0.4), lineWidth: 1.5))
        .background(palette.cardFill, in: Capsule())
    }

    // MARK: - Chord picker section
    @ViewBuilder
    private func chordPickerSection(width: CGFloat) -> some View {
        if practiceMode == .single {
            singleChordPicker(width: width)
        } else {
            progressionPicker(width: width)
        }
    }

    // Single chord: category tabs + horizontal card scroll
    private func singleChordPicker(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category tabs
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(ChordCategory.allCases) { cat in
                        Button {
                            withAnimation(.spring(response: 0.22)) { chordCategory = cat }
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(chordCategory == cat ? .black : palette.body)
                                .padding(.horizontal, 11).padding(.vertical, 5)
                                .background(chordCategory == cat ? theme.accent : palette.cardFill,
                                            in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: width)

            // Chord cards
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Chord.presets(for: chordCategory)) { chord in
                        ChordMiniCard(
                            chord: chord,
                            isActive: selectedSingle?.id == chord.id,
                            accentColor: theme.accent
                        ) {
                            withAnimation(.spring(response: 0.22)) {
                                selectedSingle = chord
                                vm.playChord(chord)
                            }
                        }
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: width)
        }
        .padding(8)
        .appCardStyle(cornerRadius: 14)
    }

    // Progression: 8-slot grid
    private func progressionPicker(width: CGFloat) -> some View {
        VStack(spacing: 8) {
            HStack {
                Text("和弦进行")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(palette.title)
                Spacer()
                // Beats per chord selector
                HStack(spacing: 0) {
                    ForEach([1, 2, 4], id: \.self) { b in
                        Button {
                            withAnimation { progression.beatsPerChord = b }
                        } label: {
                            Text("\(b)拍")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(progression.beatsPerChord == b ? .black : palette.body)
                                .padding(.horizontal, 9).padding(.vertical, 4)
                                .background(progression.beatsPerChord == b ? theme.accent : palette.cardFill)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(Capsule())
                .overlay(Capsule().stroke(theme.accent.opacity(0.18), lineWidth: 1))

                Button { withAnimation { progression.loopMode.toggle() } } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 12))
                        .foregroundColor(progression.loopMode ? theme.accent : palette.muted)
                        .padding(6)
                        .background(progression.loopMode ? theme.accent.opacity(0.18) : palette.cardFill,
                                    in: Circle())
                }

                Button { withAnimation { progression.clearAll(); assigningSlot = nil } } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(palette.muted)
                        .padding(6)
                        .background(palette.cardFill, in: Circle())
                }
            }

            // Slot grid (2 rows × 4 cols)
            let cols = Array(repeating: GridItem(.flexible(), spacing: 5), count: 4)
            LazyVGrid(columns: cols, spacing: 5) {
                ForEach(0..<ProgressionEngine.slotCount, id: \.self) { idx in
                    progressionSlotCell(index: idx)
                }
            }

            if let slot = assigningSlot {
                Text("从下方选择和弦，分配到第 \(slot + 1) 槽")
                    .font(.system(size: 11))
                    .foregroundColor(theme.accent2)
                    .transition(.opacity)

                // Inline chord category + cards for assigning
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(ChordCategory.allCases) { cat in
                            Button {
                                withAnimation(.spring(response: 0.22)) { chordCategory = cat }
                            } label: {
                                Text(cat.rawValue)
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(chordCategory == cat ? .black : palette.body)
                                    .padding(.horizontal, 9).padding(.vertical, 4)
                                    .background(chordCategory == cat ? theme.accent : palette.cardFill,
                                                in: Capsule())
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 7) {
                        ForEach(Chord.presets(for: chordCategory)) { chord in
                            Button {
                                withAnimation(.spring(response: 0.22)) {
                                    progression.assign(chord: chord, toSlot: slot)
                                    let next = (slot + 1..<ProgressionEngine.slotCount)
                                        .first { progression.slots[$0] == nil }
                                    assigningSlot = next
                                }
                            } label: {
                                Text("\(chord.emoji)\(chord.name)")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(palette.title)
                                    .padding(.horizontal, 10).padding(.vertical, 5)
                                    .background(theme.accent.opacity(0.14), in: Capsule())
                                    .overlay(Capsule().stroke(theme.accent.opacity(0.4), lineWidth: 1))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 4)
                }
            }
        }
        .padding(10)
        .appCardStyle(cornerRadius: 14)
    }

    private func progressionSlotCell(index: Int) -> some View {
        let chord      = progression.slots[index]
        let isActive   = progression.isPlaying && progression.currentSlot == index
        let isAssigning = assigningSlot == index

        return Button {
            if assigningSlot == index {
                withAnimation { assigningSlot = nil }
            } else if chord != nil {
                if !progression.isPlaying {
                    withAnimation { progression.clearSlot(index) }
                }
            } else {
                withAnimation { assigningSlot = index }
            }
        } label: {
            VStack(spacing: 2) {
                if let c = chord {
                    Text(c.emoji).font(.system(size: 11))
                    Text(c.name)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(isActive ? .black : theme.accent)
                        .lineLimit(1).minimumScaleFactor(0.6)
                } else {
                    Image(systemName: isAssigning ? "plus.circle.fill" : "plus")
                        .font(.system(size: 12))
                        .foregroundColor(isAssigning ? theme.accent : palette.muted)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(isActive    ? theme.accent :
                          isAssigning ? theme.accent.opacity(0.25) :
                          chord != nil ? palette.softFill :
                                         palette.cardFill)
                    .overlay(RoundedRectangle(cornerRadius: 8)
                        .stroke(isActive    ? theme.accent :
                                isAssigning ? theme.accent.opacity(0.80) :
                                chord != nil ? theme.accent.opacity(0.30) :
                                               theme.accent.opacity(0.12), lineWidth: 1.5))
            )
            .shadow(color: isActive ? theme.glow.opacity(0.5) : .clear, radius: 6)
            .animation(.spring(response: 0.22), value: isActive)
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive && metronome.beatFlash ? 0.92 : 1.0)
        .animation(.easeOut(duration: 0.06), value: metronome.beatFlash)
    }

    // MARK: - Start / Stop
    private var startStopButton: some View {
        Button {
            withAnimation(.spring(response: 0.25)) {
                if isPlaying { stopPractice() } else { startPractice() }
            }
        } label: {
            HStack(spacing: 10) {
                Image(systemName: isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 18, weight: .bold))
                Text(isPlaying ? "停止练习" : "开始练习")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
            }
            .foregroundColor(isPlaying ? .white : .black)
            .padding(.horizontal, 34)
            .padding(.vertical, 13)
            .background(
                Capsule()
                    .fill(isPlaying ? palette.softFill : theme.accent)
            )
            .shadow(color: isPlaying ? .clear : theme.glow.opacity(0.5), radius: 12)
            .overlay(
                Capsule()
                    .stroke(isPlaying ? theme.accent.opacity(0.18) : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Play logic
    private func startPractice() {
        isPlaying = true
        localBeat = 0
        swingAngle = 0

        if !metronome.isPlaying { metronome.start() }

        if practiceMode == .progression {
            if !progression.isPlaying {
                progression.start(bpm: metronome.bpm)
            }
        }
    }

    private func stopPractice() {
        isPlaying = false
        metronome.stop()
        if practiceMode == .progression {
            progression.stop()
        }
        withAnimation(.spring(response: 0.4)) { swingAngle = 0 }
    }

    // MARK: - Swing animation
    private func swingToNext() {
        let amplitude = 18.0   // degrees
        lastSwingRight.toggle()
        let target = lastSwingRight ? amplitude : -amplitude

        // Slightly overshoot then settle — spring feel
        withAnimation(.spring(response: 0.18, dampingFraction: 0.55)) {
            swingAngle = target
        }

        // Play the chord sound on the beat
        if let chord = activeChord {
            let dir: StrumDirection = lastSwingRight ? .downward : .upward
            vm.playChord(chord, direction: dir)
        }
    }

    private func advanceLocalBeat() {
        localBeat = (localBeat + 1) % beatCount
    }
}

// MARK: - Preview
