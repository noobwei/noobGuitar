import SwiftUI

private struct ChordChallengeCard: Identifiable {
    let id = UUID()
    let chord: Chord
    let tip: String
}

private enum ChallengeStepState {
    case pending
    case active
    case passed
}

struct DailyChordChallengeView: View {
    @ObservedObject var themeEngine: ThemeEngine
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = GuitarViewModel()
    @StateObject private var metronome = MetronomeEngine()

    @State private var selectedCategory: ChordCategory = .major
    @State private var deck: [ChordChallengeCard] = []
    @State private var currentIndex = 0
    @State private var passedCount = 0
    @State private var isPlayingReference = false

    private let palette = SurfacePalette()
    private var theme: AppTheme { themeEngine.current }
    private var currentCard: ChordChallengeCard? {
        guard deck.indices.contains(currentIndex) else { return nil }
        return deck[currentIndex]
    }

    private var progress: Double {
        guard !deck.isEmpty else { return 0 }
        return Double(passedCount) / Double(deck.count)
    }

    var body: some View {
        GeometryReader { geo in
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    header
                    categoryPicker
                    challengeSummary
                    currentStepCard(geo: geo)
                    actionRow
                    miniDeck
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
            .background(background.ignoresSafeArea())
        }
        .preferredColorScheme(.light)
        .onAppear { buildDeck() }
        .onDisappear {
            metronome.stop()
            vm.muteAll()
        }
        .onChange(of: selectedCategory) { _, _ in
            buildDeck()
        }
    }

    private var background: some View {
        LinearGradient(
            colors: [
                palette.backgroundTop,
                palette.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 5) {
                Text("轻打卡练习")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(palette.title)
                Text("一张卡只练一个和弦。你可以听参考，也可以自己决定 Pass。")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(palette.body)
            }

            Spacer()

            Button {
                dismiss()
            } label: {
                HStack(spacing: 5) {
                    Image(systemName: "chevron.left")
                    Text("返回")
                }
                .appBackButtonStyle()
            }
            .buttonStyle(.plain)
        }
    }

    private var categoryPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ChordCategory.allCases) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedCategory == category ? .white : palette.body)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? theme.accent : palette.cardFill)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private var challengeSummary: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("进度")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(palette.title)
                Spacer()
                Text("\(passedCount)/\(deck.count)")
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(theme.accent)
            }

            GeometryReader { proxy in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(palette.softFill)
                    Capsule()
                        .fill(theme.accent)
                        .frame(width: proxy.size.width * progress)
                }
            }
            .frame(height: 10)

            HStack(spacing: 12) {
                summaryChip(title: "BPM", value: "\(metronome.bpm)")
                summaryChip(title: "卡片", value: deck.isEmpty ? "0" : "\(currentIndex + 1)")
                summaryChip(title: "模式", value: "手动 Pass")
            }
        }
        .padding(16)
        .appCardStyle()
    }

    private func summaryChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(palette.muted)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(palette.title)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func currentStepCard(geo: GeometryProxy) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let card = currentCard {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("当前卡片")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(palette.muted)
                        HStack(spacing: 10) {
                            Text(card.chord.emoji)
                                .font(.system(size: 26))
                            Text(card.chord.name)
                                .font(.system(size: 40, weight: .black, design: .rounded))
                                .foregroundColor(theme.accent)
                        }
                    }

                    Spacer()

                    Button {
                        playReference()
                    } label: {
                        Label(isPlayingReference ? "播放中" : "听参考", systemImage: isPlayingReference ? "waveform" : "play.fill")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 9)
                            .background(theme.accent, in: Capsule())
                    }
                    .buttonStyle(.plain)
                }

                miniDiagram(card.chord)
                Text(card.tip)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(palette.body)

                VStack(alignment: .leading, spacing: 6) {
                    Text("练习速度")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.muted)
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

                FretboardView(vm: vm)
                    .frame(height: min(geo.size.height * 0.30, 240))
                    .background(Color(red: 0.34, green: 0.24, blue: 0.14), in: RoundedRectangle(cornerRadius: 20))
            } else {
                Text("当前分类没有可用和弦")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(palette.title)
            }
        }
        .padding(18)
        .appCardStyle(cornerRadius: 28)
    }

    private var actionRow: some View {
        HStack(spacing: 12) {
            Button {
                previousCard()
            } label: {
                actionLabel(title: "上一张", fill: Color.white.opacity(0.82), foreground: Color(red: 0.28, green: 0.22, blue: 0.16))
            }
            .buttonStyle(.plain)

            Button {
                markPassed()
            } label: {
                actionLabel(title: currentIndex + 1 >= deck.count ? "完成打卡" : "我觉得过了", fill: theme.accent, foreground: .white)
            }
            .buttonStyle(.plain)

            Button {
                skipCard()
            } label: {
                actionLabel(title: "跳过", fill: theme.accent2.opacity(0.25), foreground: Color(red: 0.23, green: 0.18, blue: 0.13))
            }
            .buttonStyle(.plain)
        }
    }

    private func actionLabel(title: String, fill: Color, foreground: Color) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(fill, in: RoundedRectangle(cornerRadius: 18))
    }

    private var miniDeck: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("卡片列表")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Array(deck.enumerated()), id: \.element.id) { index, card in
                        let state = stepState(for: index)
                        Button {
                            currentIndex = index
                            vm.playChord(card.chord)
                        } label: {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(card.chord.name)
                                    .font(.system(size: 14, weight: .black, design: .rounded))
                                Text(card.tip)
                                    .font(.system(size: 11, weight: .medium))
                                    .lineLimit(2)
                            }
                            .foregroundColor(state == .active ? .white : palette.title)
                            .frame(width: 130, height: 88, alignment: .topLeading)
                            .padding(12)
                            .background(cardBackground(state: state), in: RoundedRectangle(cornerRadius: 20))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    private func cardBackground(state: ChallengeStepState) -> Color {
        switch state {
        case .pending:
            return Color.white.opacity(0.82)
        case .active:
            return theme.accent
        case .passed:
            return Color(red: 0.79, green: 0.91, blue: 0.78)
        }
    }

    private func stepState(for index: Int) -> ChallengeStepState {
        if index < passedCount { return .passed }
        if index == currentIndex { return .active }
        return .pending
    }

    private func miniDiagram(_ chord: Chord) -> some View {
        HStack(spacing: 6) {
            ForEach(0..<6, id: \.self) { string in
                let fret = chord.frets[string]
                VStack(spacing: 6) {
                    Text(["E","A","D","G","B","e"][string])
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(palette.muted)
                    ZStack {
                        Circle()
                            .fill(fret < 0 ? Color.red.opacity(0.18) : theme.accent.opacity(fret == 0 ? 0.12 : 0.22))
                            .frame(width: 30, height: 30)
                        Text(fret < 0 ? "X" : fret == 0 ? "0" : "\(fret)")
                            .font(.system(size: 13, weight: .black, design: .rounded))
                            .foregroundColor(fret < 0 ? .red : palette.title)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func buildDeck() {
        let source = Array(Chord.presets(for: selectedCategory).prefix(8))
        deck = source.enumerated().map { index, chord in
            ChordChallengeCard(chord: chord, tip: practiceTip(index: index, chord: chord))
        }
        currentIndex = 0
        passedCount = 0
        if let first = deck.first?.chord {
            vm.playChord(first)
        }
    }

    private func practiceTip(index: Int, chord: Chord) -> String {
        let tips = [
            "先摆好左手，再慢速顺扫 4 次。",
            "只关注最容易闷住的那根弦。",
            "扫弦前先单独拨响根音确认。",
            "保持手腕放松，别急着提速。"
        ]
        return "\(chord.name)：\(tips[index % tips.count])"
    }

    private func playReference() {
        guard let chord = currentCard?.chord else { return }
        isPlayingReference = true
        if !metronome.isPlaying { metronome.start() }
        vm.playChord(chord)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isPlayingReference = false
        }
    }

    private func markPassed() {
        guard !deck.isEmpty else { return }
        passedCount = max(passedCount, currentIndex + 1)
        if currentIndex + 1 < deck.count {
            currentIndex += 1
            if let chord = currentCard?.chord { vm.playChord(chord) }
        } else {
            metronome.stop()
        }
    }

    private func skipCard() {
        guard !deck.isEmpty else { return }
        currentIndex = min(currentIndex + 1, deck.count - 1)
        if let chord = currentCard?.chord { vm.playChord(chord) }
    }

    private func previousCard() {
        guard !deck.isEmpty else { return }
        currentIndex = max(currentIndex - 1, 0)
        if let chord = currentCard?.chord { vm.playChord(chord) }
    }
}
