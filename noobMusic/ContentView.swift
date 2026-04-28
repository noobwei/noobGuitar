import SwiftUI
import UIKit

// MARK: - Panel identity (for drag-reorder)
enum PanelID: String, CaseIterable, Identifiable {
    var id: String { rawValue }
    case strum = "strum"
    case info  = "info"
    case capo  = "capo"
}

struct ContentView: View {
    @StateObject private var vm          = GuitarViewModel()
    @StateObject private var metronome   = MetronomeEngine()
    @StateObject private var mic         = MicListenerEngine()
    @StateObject private var progression = ProgressionEngine()
    @StateObject private var themeEngine = ThemeEngine()
    @StateObject private var practiceLog = PracticeLogEngine()

    @State private var lastStrumTime   : Date          = .distantPast
    @State private var chordCategory   : ChordCategory = .major
    @State private var showMetronome   : Bool          = false
    @State private var showMic         : Bool          = false
    @State private var showThemePicker : Bool          = false
    @State private var assigningSlot   : Int?          = nil
    @State private var showStrumPractice: Bool         = false
    @State private var showPracticeLog : Bool          = false

    // ── Drag-reorder state ───────────────────────────────────────────
    @State private var panelOrder: [PanelID] = {
        let saved  = UserDefaults.standard.string(forKey: "panel_order") ?? ""
        let mapped = saved.split(separator: ",").compactMap { PanelID(rawValue: String($0)) }
        return mapped.count == 3 ? mapped : [.strum, .info, .capo]
    }()
    @State private var draggingPanel   : PanelID? = nil
    @State private var dragTranslation : CGFloat  = 0

    private var theme: AppTheme { themeEngine.current }

    // MARK: - Body
    var body: some View {
        GeometryReader { geo in
            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.10, green: 0.06, blue: 0.02),
                             Color(red: 0.18, green: 0.11, blue: 0.04)],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                if geo.size.width > geo.size.height {
                    landscapeLayout(geo: geo)
                } else {
                    portraitLayout(geo: geo)
                }

                if showThemePicker {
                    themePickerOverlay
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .preferredColorScheme(.dark)
        .ignoresSafeArea(edges: .bottom)
        .onChange(of: vm.selectedChord) { mic.targetChord = vm.selectedChord }
        .onChange(of: metronome.bpm)    { progression.updateBPM(metronome.bpm) }
        .onAppear {
            let vmRef = vm
            progression.onChordChange = { chord in
                guard let chord else { return }
                vmRef.playChord(chord)
            }
            progression.updateBPM(metronome.bpm)
        }
        .fullScreenCover(isPresented: $showStrumPractice) {
            StrumPracticeView(
                vm: vm,
                metronome: metronome,
                progression: progression,
                themeEngine: themeEngine
            )
        }
        .fullScreenCover(isPresented: $showPracticeLog) {
            PracticeLogView(log: practiceLog, themeEngine: themeEngine)
        }
        .onAppear  { practiceLog.startTracking() }
        .onDisappear { practiceLog.stopTracking() }
    }

    // MARK: - Dynamic sizing
    private func fretboardHeight(_ geo: GeometryProxy) -> CGFloat {
        geo.size.width > geo.size.height
            ? geo.size.height * 0.72
            : min(260, geo.size.height * 0.30)
    }
    private func middlePanelHeight(_ geo: GeometryProxy) -> CGFloat {
        geo.size.width > geo.size.height
            ? min(130, (geo.size.height * 0.60) / 3)
            : min(148, geo.size.height * 0.185)
    }

    // MARK: - Portrait layout
    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            headerBar
                .padding(.top, 12)

            FretboardView(vm: vm)
                .frame(height: fretboardHeight(geo))
                .padding(.horizontal, 16)
                .padding(.top, 10)

            orderedPanelsHStack(geo: geo)
                .padding(.horizontal, 16)
                .padding(.top, 10)

            collapsiblePanels
                .padding(.horizontal, 16)
                .animation(.spring(response: 0.28), value: showMetronome)
                .animation(.spring(response: 0.28), value: showMic)

            chordSection.padding(.top, 10)
            Spacer(minLength: 8)
        }
    }

    // MARK: - Landscape layout
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        // Reserve space: header ~48pt, safe area breathing room
        let headerH  : CGFloat = 48
        let hPad     : CGFloat = 12   // horizontal edge padding
        let colGap   : CGFloat = 10
        let leftW    = (geo.size.width - hPad * 2 - colGap) * 0.54
        let rightW   = (geo.size.width - hPad * 2 - colGap) * 0.46
        let fbH      = geo.size.height - headerH - 8

        return VStack(spacing: 0) {
            headerBar
                .padding(.top, 4)
                .frame(height: headerH)

            HStack(alignment: .top, spacing: colGap) {
                // Left: fretboard only — fills full remaining height
                FretboardView(vm: vm)
                    .frame(width: leftW, height: fbH)

                // Right: panels + collapsibles + chord section — all scrollable
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 8) {
                        orderedPanelsVStack(panelWidth: rightW, geo: geo)
                        collapsiblePanels
                            .animation(.spring(response: 0.28), value: showMetronome)
                            .animation(.spring(response: 0.28), value: showMic)
                        // Chord section lives in the right column in landscape
                        chordSectionCompact(width: rightW)
                    }
                    .padding(.bottom, 12)
                }
                .frame(width: rightW)
            }
            .padding(.horizontal, hPad)
        }
    }

    // MARK: - Ordered panels — HStack (portrait)
    private func orderedPanelsHStack(geo: GeometryProxy) -> some View {
        let panelW = (geo.size.width - 32 - 20) / 3
        return HStack(spacing: 10) {
            panelForEach(
                size: CGSize(width: panelW, height: middlePanelHeight(geo)),
                axis: .horizontal
            )
        }
    }

    // MARK: - Ordered panels — VStack (landscape)
    private func orderedPanelsVStack(panelWidth: CGFloat, geo: GeometryProxy) -> some View {
        VStack(spacing: 8) {
            panelForEach(
                size: CGSize(width: panelWidth, height: middlePanelHeight(geo)),
                axis: .vertical
            )
        }
    }

    // MARK: - ForEach with long-press drag-to-reorder
    @ViewBuilder
    private func panelForEach(size: CGSize, axis: Axis) -> some View {
        ForEach(Array(panelOrder.enumerated()), id: \.element) { idx, pid in
            panelView(for: pid)
                .frame(width: size.width, height: size.height)
                .scaleEffect(draggingPanel == pid ? 1.05 : 1.0)
                .shadow(color: draggingPanel == pid ? theme.accent.opacity(0.55) : .clear,
                        radius: draggingPanel == pid ? 14 : 0)
                .offset(
                    x: (axis == .horizontal && draggingPanel == pid) ? dragTranslation : 0,
                    y: (axis == .vertical   && draggingPanel == pid) ? dragTranslation : 0
                )
                .zIndex(draggingPanel == pid ? 10 : 0)
                .overlay(alignment: .topLeading) {
                    if draggingPanel == pid {
                        Image(systemName: axis == .horizontal ? "arrow.left.and.right" : "arrow.up.and.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.85))
                            .padding(.horizontal, 5).padding(.vertical, 3)
                            .background(theme.accent.opacity(0.55), in: Capsule())
                            .padding(5)
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .gesture(
                    LongPressGesture(minimumDuration: 0.4)
                        .onEnded { _ in
                            withAnimation(.spring(response: 0.2)) { draggingPanel = pid }
                            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        }
                        .sequenced(before:
                            DragGesture()
                                .onChanged { v in
                                    guard draggingPanel == pid else { return }
                                    dragTranslation = axis == .horizontal
                                        ? v.translation.width
                                        : v.translation.height
                                }
                                .onEnded { v in
                                    guard draggingPanel == pid else { return }
                                    let delta = axis == .horizontal
                                        ? v.translation.width
                                        : v.translation.height
                                    let step  = axis == .horizontal
                                        ? size.width + 10
                                        : size.height + 8
                                    let shift  = Int((delta / step).rounded())
                                    let newIdx = (idx + shift).clamped(to: 0...(panelOrder.count - 1))
                                    if newIdx != idx {
                                        withAnimation(.spring(response: 0.25)) {
                                            let item = panelOrder.remove(at: idx)
                                            panelOrder.insert(item, at: newIdx)
                                        }
                                        savePanelOrder()
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                    }
                                    withAnimation(.spring(response: 0.2)) {
                                        draggingPanel   = nil
                                        dragTranslation = 0
                                    }
                                }
                        )
                )
        }
    }

    private func panelView(for pid: PanelID) -> some View {
        Group {
            switch pid {
            case .strum: strumArea
            case .info:  infoPanel
            case .capo:  capoPanel
            }
        }
    }

    private func savePanelOrder() {
        UserDefaults.standard.set(
            panelOrder.map(\.rawValue).joined(separator: ","),
            forKey: "panel_order"
        )
    }

    // MARK: - Collapsible panels
    @ViewBuilder
    private var collapsiblePanels: some View {
        if showMetronome {
            metronomePanel
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
        if showMic {
            micPanel
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text("🎸 Acoustic Guitar")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Group {
                    if let chord = vm.selectedChord {
                        Text("和弦  \(chord.name)\(vm.capoFret > 0 ? "  Capo \(vm.capoFret)" : "")")
                            .foregroundColor(theme.accent)
                    } else if !vm.lastNote.isEmpty, let det = vm.detectedChord {
                        Text("识别到  \(det)")
                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.7))
                    } else if !vm.lastNote.isEmpty {
                        Text("单音  \(vm.lastNote)")
                            .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.7))
                    } else {
                        Text("点击指板或和弦开始演奏")
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .font(.system(size: 13, weight: .medium))
                .animation(.easeInOut(duration: 0.2), value: vm.lastNote)
            }

            Spacer()

            toolbarButton(icon: "metronome.fill",
                          active: showMetronome || metronome.isPlaying,
                          color: theme.accent) {
                withAnimation(.spring(response: 0.28)) { showMetronome.toggle() }
            }
            toolbarButton(icon: "mic.fill",
                          active: showMic || mic.isListening,
                          color: Color(red: 0.4, green: 0.9, blue: 0.7)) {
                withAnimation(.spring(response: 0.28)) { showMic.toggle() }
            }
            toolbarButton(icon: "paintpalette.fill",
                          active: showThemePicker,
                          color: theme.accent2) {
                withAnimation(.spring(response: 0.28)) { showThemePicker.toggle() }
            }
            toolbarButton(icon: "speaker.slash.fill", active: false, color: .white.opacity(0.55)) {
                withAnimation { vm.muteAll() }
            }
            toolbarButton(icon: "figure.strengthtraining.traditional",
                          active: false,
                          color: theme.accent2) {
                showStrumPractice = true
            }
            toolbarButton(icon: "calendar.badge.checkmark",
                          active: showPracticeLog,
                          color: Color(red: 0.4, green: 0.85, blue: 0.5)) {
                showPracticeLog = true
            }
        }
        .padding(.horizontal, 18)
    }

    private func toolbarButton(icon: String, active: Bool, color: Color,
                               action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 17))
                .foregroundColor(active ? color : .white.opacity(0.50))
                .padding(9)
                .background(active ? color.opacity(0.18) : Color.white.opacity(0.08), in: Circle())
        }
    }

    // MARK: - Strum area
    private var strumArea: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.10), lineWidth: 1))

            VStack(spacing: 6) {
                Image(systemName: "hand.draw.fill")
                    .font(.system(size: 18))
                    .foregroundColor(theme.accent.opacity(0.8))

                Text("上下滑动扫弦")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))

                HStack(spacing: 8) {
                    strumButton("↓ 顺扫", direction: .downward)
                    strumButton("↑ 逆扫", direction: .upward)
                }

                HStack(spacing: 0) {
                    ForEach(StrumSpeed.options.indices, id: \.self) { i in
                        let sp = StrumSpeed.options[i]
                        Button { vm.strumSpeedIndex = i } label: {
                            Text(sp.label)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(vm.strumSpeedIndex == i ? .black : .white.opacity(0.6))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 4)
                                .background(vm.strumSpeedIndex == i
                                            ? theme.accent
                                            : Color.white.opacity(0.08))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))
                .padding(.horizontal, 6)
            }
            .padding(.horizontal, 6)
        }
        .gesture(
            DragGesture(minimumDistance: 20)
                .onEnded { value in
                    let now = Date()
                    guard now.timeIntervalSince(lastStrumTime) > 0.25 else { return }
                    lastStrumTime = now
                    let dir: StrumDirection = value.translation.height > 0 ? .downward : .upward
                    doStrum(direction: dir)
                }
        )
    }

    private func strumButton(_ label: String, direction: StrumDirection) -> some View {
        Button { doStrum(direction: direction) } label: {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(theme.accent.opacity(0.25), in: Capsule())
        }
    }

    private func doStrum(direction: StrumDirection) {
        let frets = vm.fretPosition.map { max(0, $0) }
        if let chord = vm.selectedChord {
            for (i, f) in chord.frets.enumerated() where f < 0 { vm.engine.mute(string: i) }
        }
        vm.engine.strum(frets: frets, direction: direction, delay: vm.strumDelay)
        vm.lastNote = ""
    }

    // MARK: - Info panel
    private var infoPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            (vm.lastNote.isEmpty && vm.detectedChord == nil)
                                ? Color.white.opacity(0.10)
                                : Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.40),
                            lineWidth: 1.5
                        )
                )

            if vm.lastNote.isEmpty && vm.detectedChord == nil {
                VStack(spacing: 6) {
                    Image(systemName: "music.note.list")
                        .font(.system(size: 20))
                        .foregroundColor(.white.opacity(0.15))
                    Text("按下琴弦\n查看音名/和弦")
                        .font(.system(size: 10))
                        .multilineTextAlignment(.center)
                        .foregroundColor(.white.opacity(0.22))
                }
            } else {
                VStack(spacing: 4) {
                    if let det = vm.detectedChord {
                        VStack(spacing: 1) {
                            Text("识别和弦")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.35))
                            Text(det)
                                .font(.system(size: 32, weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.7))
                                .shadow(color: Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.4), radius: 8)
                                .id("det_\(det)")
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    if !vm.lastNote.isEmpty {
                        HStack(spacing: 5) {
                            Text(vm.lastNoteLetter)
                                .font(.system(size: vm.detectedChord == nil ? 40 : 18,
                                              weight: .black, design: .rounded))
                                .foregroundColor(Color(red: 0.4, green: 0.9, blue: 0.7))
                                .id(vm.lastNote)
                            if vm.detectedChord == nil {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(vm.lastNote)
                                        .font(.system(size: 11, weight: .medium, design: .monospaced))
                                        .foregroundColor(.white.opacity(0.50))
                                    stringFretBadges
                                }
                            } else {
                                stringFretBadges
                            }
                        }
                    }
                }
                .animation(.spring(response: 0.3), value: vm.lastNote)
                .animation(.spring(response: 0.3), value: vm.detectedChord)
                .padding(8)
            }
        }
    }

    private var stringFretBadges: some View {
        HStack(spacing: 3) {
            if vm.lastNoteString >= 0 {
                Text(GuitarAudioEngine.openStringNames[safe: vm.lastNoteString] ?? "")
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(theme.accent)
                    .padding(.horizontal, 4).padding(.vertical, 2)
                    .background(theme.accent.opacity(0.18), in: Capsule())
            }
            Text(vm.lastNoteFret == 0 ? "空弦" : "第\(vm.lastNoteFret)品")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.white.opacity(0.45))
                .padding(.horizontal, 4).padding(.vertical, 2)
                .background(Color.white.opacity(0.08), in: Capsule())
        }
    }

    // MARK: - Capo Panel
    private var capoPanel: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(vm.capoFret > 0
                            ? Color(red: 0.9, green: 0.7, blue: 0.2).opacity(0.5)
                            : Color.white.opacity(0.10), lineWidth: 1.5))

            VStack(spacing: 5) {
                Text("变调夹")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.40))

                if vm.capoFret > 0 {
                    Text("第\(vm.capoFret)品")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.9, green: 0.7, blue: 0.2))
                        .transition(.scale)
                } else {
                    Text("无")
                        .font(.system(size: 16, weight: .black, design: .rounded))
                        .foregroundColor(.white.opacity(0.20))
                }

                HStack(spacing: 8) {
                    capoStepButton(icon: "minus") {
                        if vm.capoFret > 0 { withAnimation { vm.capoFret -= 1 } }
                    }
                    capoStepButton(icon: "plus") {
                        if vm.capoFret < 7 { withAnimation { vm.capoFret += 1 } }
                    }
                }

                if vm.capoFret > 0 {
                    Button { withAnimation { vm.capoFret = 0 } } label: {
                        Text("取消")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(theme.accent)
                    }
                }
            }
            .padding(.vertical, 6)
        }
    }

    private func capoStepButton(icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.75))
                .frame(width: 26, height: 26)
                .background(Color.white.opacity(0.10), in: Circle())
        }
    }

    // MARK: - Metronome Panel
    private var metronomePanel: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(metronome.beatFlash ? theme.accent : Color.white.opacity(0.12))
                .frame(width: 46, height: 46)
                .shadow(color: metronome.beatFlash ? theme.glow.opacity(0.7) : .clear, radius: 10)
                .animation(.easeOut(duration: 0.05), value: metronome.beatFlash)

            VStack(spacing: 4) {
                Text("\(metronome.bpm)  BPM")
                    .font(.system(size: 30, weight: .black, design: .rounded))
                    .foregroundColor(.white)

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

            Button { metronome.toggle() } label: {
                Image(systemName: metronome.isPlaying ? "stop.fill" : "play.fill")
                    .font(.system(size: 20))
                    .foregroundColor(metronome.isPlaying ? theme.accent : .white)
                    .frame(width: 46, height: 46)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.accent.opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Progression Bar
    private var progressionBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 10) {
                Text("🎼 和弦进行")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 0) {
                    ForEach([1, 2, 4], id: \.self) { beats in
                        Button {
                            withAnimation { progression.beatsPerChord = beats }
                        } label: {
                            Text("\(beats)拍")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(progression.beatsPerChord == beats ? .black : .white.opacity(0.6))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 4)
                                .background(progression.beatsPerChord == beats
                                            ? theme.accent
                                            : Color.white.opacity(0.08))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .clipShape(Capsule())
                .overlay(Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1))

                Button {
                    withAnimation { progression.loopMode.toggle() }
                } label: {
                    Image(systemName: "repeat")
                        .font(.system(size: 13))
                        .foregroundColor(progression.loopMode ? theme.accent : .white.opacity(0.35))
                        .padding(6)
                        .background(progression.loopMode
                                    ? theme.accent.opacity(0.18)
                                    : Color.white.opacity(0.08), in: Circle())
                }

                Button {
                    withAnimation { progression.clearAll(); assigningSlot = nil }
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.45))
                        .padding(6)
                        .background(Color.white.opacity(0.08), in: Circle())
                }

                Button {
                    if progression.isPlaying {
                        progression.stop(); metronome.stop()
                    } else {
                        if !metronome.isPlaying { metronome.start() }
                        progression.start(bpm: metronome.bpm)
                    }
                } label: {
                    Image(systemName: progression.isPlaying ? "stop.fill" : "play.fill")
                        .font(.system(size: 15))
                        .foregroundColor(progression.isPlaying ? theme.accent : .white)
                        .frame(width: 34, height: 34)
                        .background(Color.white.opacity(0.10), in: Circle())
                }
            }

            HStack(spacing: 5) {
                ForEach(0..<ProgressionEngine.slotCount, id: \.self) { idx in
                    progressionSlot(index: idx)
                }
            }

            if let slot = assigningSlot {
                Text("点击下方和弦库，分配到第 \(slot + 1) 槽")
                    .font(.system(size: 11))
                    .foregroundColor(theme.accent2)
                    .transition(.opacity)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 16)
                    .stroke(theme.accent.opacity(0.22), lineWidth: 1))
        )
    }

    private func progressionSlot(index: Int) -> some View {
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
                    Text(c.emoji).font(.system(size: 12))
                    Text(c.name)
                        .font(.system(size: 11, weight: .black, design: .rounded))
                        .foregroundColor(isActive ? .black : theme.accent)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                } else {
                    Image(systemName: isAssigning ? "plus.circle.fill" : "plus")
                        .font(.system(size: 14))
                        .foregroundColor(isAssigning ? theme.accent : .white.opacity(0.22))
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isActive    ? theme.accent :
                          isAssigning ? theme.accent.opacity(0.25) :
                          chord != nil ? Color.white.opacity(0.10) :
                                         Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(isActive    ? theme.accent :
                                    isAssigning ? theme.accent.opacity(0.80) :
                                    chord != nil ? theme.accent.opacity(0.30) :
                                                   Color.white.opacity(0.10),
                                    lineWidth: isActive ? 0 : 1.5)
                    )
            )
            .shadow(color: isActive ? theme.glow.opacity(0.5) : .clear, radius: 8)
            .animation(.spring(response: 0.22), value: isActive)
        }
        .buttonStyle(.plain)
        .scaleEffect(isActive && metronome.beatFlash ? 0.92 : 1.0)
        .animation(.easeOut(duration: 0.06), value: metronome.beatFlash)
        .contextMenu {
            if chord != nil {
                Button(role: .destructive) {
                    withAnimation { progression.clearSlot(index) }
                } label: {
                    Label("清除此槽", systemImage: "trash")
                }
            }
        }
    }

    // MARK: - Mic Panel
    private var micPanel: some View {
        HStack(spacing: 14) {
            Button { mic.toggle() } label: {
                Image(systemName: mic.isListening ? "mic.fill" : "mic.slash.fill")
                    .font(.system(size: 18))
                    .foregroundColor(mic.isListening
                                     ? Color(red: 0.4, green: 0.9, blue: 0.7)
                                     : .white.opacity(0.45))
                    .frame(width: 44, height: 44)
                    .background(mic.isListening
                                ? Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.15)
                                : Color.white.opacity(0.08), in: Circle())
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(mic.isListening ? "监听中..." : "开始监听真实吉他")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white)
                if let chord = vm.selectedChord {
                    Text("目标和弦: \(chord.name)")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.45))
                } else {
                    Text("请先选择一个和弦")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.30))
                }
                if !mic.detectedNote.isEmpty {
                    Text("检测音: \(mic.detectedNote)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.white.opacity(0.50))
                }
            }

            Spacer()
            micScoreRing
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(mic.isListening
                                ? Color(red: 0.4, green: 0.9, blue: 0.7).opacity(0.30)
                                : Color.white.opacity(0.10), lineWidth: 1)
                )
        )
    }

    private var micScoreRing: some View {
        let scoreColor: Color = mic.feedbackColor
        let score = mic.matchScore
        return ZStack {
            Circle()
                .stroke(Color.white.opacity(0.10), lineWidth: 5)
                .frame(width: 54, height: 54)
            Circle()
                .trim(from: 0, to: score)
                .stroke(scoreColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                .frame(width: 54, height: 54)
                .rotationEffect(.degrees(-90))
                .animation(.spring(response: 0.4), value: score)
            VStack(spacing: 1) {
                Text("\(Int(score * 100))%")
                    .font(.system(size: 12, weight: .black, design: .rounded))
                    .foregroundColor(scoreColor)
                Text(micFeedbackLabel)
                    .font(.system(size: 7, weight: .medium))
                    .foregroundColor(.white.opacity(0.40))
            }
        }
    }

    private var micFeedbackLabel: String {
        if mic.matchScore > 0.75 { return "完美" }
        if mic.matchScore > 0.45 { return "接近" }
        if mic.matchScore > 0.1  { return "加油" }
        return "等待..."
    }

    // MARK: - Chord Section
    private var chordSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(ChordCategory.allCases) { cat in
                        Button {
                            withAnimation(.spring(response: 0.25)) { chordCategory = cat }
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(chordCategory == cat ? .black : .white.opacity(0.6))
                                .padding(.horizontal, 13)
                                .padding(.vertical, 6)
                                .background(chordCategory == cat
                                            ? theme.accent
                                            : Color.white.opacity(0.10), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 9) {
                    ForEach(Chord.presets(for: chordCategory)) { chord in
                        chordButton(chord)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }

    // MARK: - Chord Section (compact, width-constrained — used in landscape right column)
    private func chordSectionCompact(width: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            // Category tabs — horizontal scroll, constrained width
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 7) {
                    ForEach(ChordCategory.allCases) { cat in
                        Button {
                            withAnimation(.spring(response: 0.25)) { chordCategory = cat }
                        } label: {
                            Text(cat.rawValue)
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(chordCategory == cat ? .black : .white.opacity(0.6))
                                .padding(.horizontal, 11)
                                .padding(.vertical, 5)
                                .background(chordCategory == cat
                                            ? theme.accent
                                            : Color.white.opacity(0.10), in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: width)

            // Chord cards — horizontal scroll, constrained width
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Chord.presets(for: chordCategory)) { chord in
                        chordButton(chord)
                    }
                }
                .padding(.horizontal, 4)
            }
            .frame(width: width)
        }
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func chordButton(_ chord: Chord) -> some View {
        let isSelected  = vm.selectedChord?.id == chord.id
        let isAssigning = assigningSlot != nil

        return Button {
            if let slot = assigningSlot {
                withAnimation(.spring(response: 0.22)) {
                    progression.assign(chord: chord, toSlot: slot)
                    let next = (slot + 1..<ProgressionEngine.slotCount).first { progression.slots[$0] == nil }
                    assigningSlot = next
                }
            } else {
                withAnimation(.spring(response: 0.22)) { vm.playChord(chord) }
            }
        } label: {
            VStack(spacing: 3) {
                Text(chord.emoji).font(.system(size: 16))
                Text(chord.name)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(isSelected ? theme.accent : .white)
                miniDiagram(chord.frets)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected  ? theme.accent.opacity(0.20) :
                          isAssigning ? theme.accent.opacity(0.08) :
                                        Color.white.opacity(0.07))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected  ? theme.accent.opacity(0.6) :
                                isAssigning ? theme.accent.opacity(0.35) :
                                              Color.clear, lineWidth: 1.5))
            )
        }
        .buttonStyle(.plain)
    }

    private func miniDiagram(_ frets: [Int]) -> some View {
        HStack(spacing: 2) {
            ForEach(0..<6, id: \.self) { s in
                let f = frets[s]
                ZStack {
                    Circle()
                        .fill(f < 0 ? Color.red.opacity(0.35) : Color.white.opacity(0.12))
                        .frame(width: 9, height: 9)
                    if f > 0 {
                        Text("\(f)").font(.system(size: 5, weight: .bold)).foregroundColor(theme.accent)
                    } else if f < 0 {
                        Text("✕").font(.system(size: 5, weight: .bold)).foregroundColor(.red.opacity(0.7))
                    }
                }
            }
        }
    }

    // MARK: - Theme Picker Overlay
    private var themePickerOverlay: some View {
        ZStack {
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { withAnimation { showThemePicker = false } }

            VStack(spacing: 16) {
                Text("选择主题颜色")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                HStack(spacing: 14) {
                    ForEach(AppTheme.presets) { t in themeChip(t) }
                }

                Button {
                    withAnimation { showThemePicker = false }
                } label: {
                    Text("完成")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 8)
                        .background(theme.accent.opacity(0.25), in: Capsule())
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(Color(red: 0.12, green: 0.08, blue: 0.04))
                    .overlay(RoundedRectangle(cornerRadius: 22)
                        .stroke(theme.accent.opacity(0.30), lineWidth: 1.5))
            )
            .shadow(radius: 30)
        }
    }

    private func themeChip(_ t: AppTheme) -> some View {
        let isSelected = themeEngine.current.id == t.id
        return Button { themeEngine.select(t) } label: {
            VStack(spacing: 5) {
                Circle()
                    .fill(t.accent)
                    .frame(width: 38, height: 38)
                    .overlay(Circle().stroke(Color.white.opacity(isSelected ? 1.0 : 0), lineWidth: 3))
                    .shadow(color: isSelected ? t.glow.opacity(0.7) : .clear, radius: 8)
                Text(t.name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(isSelected ? t.accent : .white.opacity(0.55))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .frame(width: 48)
            }
            .scaleEffect(isSelected ? 1.10 : 1.0)
            .animation(.spring(response: 0.25), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Safe array subscript
private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    ContentView()
}
