import SwiftUI

private enum TabInsertTemplate: String, CaseIterable, Identifiable {
    case blank = "空白"
    case downStrum = "顺扫"
    case arpeggio = "分解"
    case mutedGroove = "制音"

    var id: String { rawValue }

    var techniqueLabel: String {
        switch self {
        case .blank:
            return "右手: 自由安排"
        case .downStrum:
            return "右手:   ↓     ↓     ↑     ↓"
        case .arpeggio:
            return "右手:   P(5-4-3-2)    P(5-4-3-2)"
        case .mutedGroove:
            return "右手:   ↓     x     ↑     x"
        }
    }
}

private struct TabMeasure: Identifiable {
    let id = UUID()
    var title: String
    var chord: Chord
    var beats: Int
    var techniqueLabel: String
    var rows: [String]
}

private struct TabStaffEditorRow: View {
    let label: String
    @Binding var value: String
    let palette: SurfacePalette

    var body: some View {
        HStack(spacing: 8) {
            Text("\(label)|")
                .font(.system(size: 15, weight: .bold, design: .monospaced))
                .foregroundColor(palette.title)
                .frame(width: 28, alignment: .leading)

            TextField("------------------------", text: $value)
                .textFieldStyle(.plain)
                .font(.system(size: 15, weight: .medium, design: .monospaced))
                .foregroundColor(palette.title)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        }
    }
}

struct TabComposerView: View {
    @ObservedObject var themeEngine: ThemeEngine
    @Environment(\.dismiss) private var dismiss

    @StateObject private var vm = GuitarViewModel()
    @State private var title = "我的练习谱"
    @State private var selectedCategory: ChordCategory = .major
    @State private var selectedChord: Chord = Chord.presets(for: .major).first ?? Chord.presets[0]
    @State private var measures: [TabMeasure] = []

    private let palette = SurfacePalette()
    private let stringLabels = ["e", "B", "G", "D", "A", "E"]
    private var theme: AppTheme { themeEngine.current }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    palette.backgroundTop,
                    palette.backgroundBottom
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 18) {
                    header
                    overviewCard
                    chordPaletteCard
                    measureSection
                    fullPreviewCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.light)
        .onAppear {
            if measures.isEmpty {
                measures = [
                    makeMeasure(chord: selectedChord, template: .downStrum, title: "主歌第 1 小节"),
                    makeMeasure(chord: Chord.presets(for: .major).dropFirst().first ?? selectedChord,
                                template: .arpeggio,
                                title: "主歌第 2 小节")
                ]
            }
        }
        .onChange(of: selectedCategory) { _, newValue in
            selectedChord = Chord.presets(for: newValue).first ?? Chord.presets[0]
        }
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("谱本")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(palette.title)
                Text("按六线谱方式写下每根弦、右手动作和小节结构。")
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

    private var overviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("标题")
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            TextField("输入谱子标题", text: $title)
                .textFieldStyle(.plain)
                .font(.system(size: 22, weight: .black, design: .rounded))
                .foregroundColor(palette.title)
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white, in: RoundedRectangle(cornerRadius: 18))

            HStack(spacing: 12) {
                overviewChip(title: "小节", value: "\(measures.count)")
                overviewChip(title: "当前和弦", value: selectedChord.name)
                overviewChip(title: "类别", value: selectedCategory.rawValue)
            }
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.accent.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.accent.opacity(0.20), lineWidth: 1)
                )
        )
    }

    private func overviewChip(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(palette.muted)
            Text(value)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(palette.title)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var chordPaletteCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("和弦素材")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(palette.title)
                Spacer()
                Button {
                    measures.append(makeMeasure(chord: selectedChord, template: .blank, title: "新小节"))
                } label: {
                    Label("新增小节", systemImage: "plus")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(theme.accent, in: Capsule())
                }
                .buttonStyle(.plain)
            }

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
                                .background(selectedCategory == category ? theme.accent : palette.cardFill, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(Chord.presets(for: selectedCategory)) { chord in
                        Button {
                            selectedChord = chord
                        } label: {
                            VStack(spacing: 4) {
                                Text(chord.emoji)
                                    .font(.system(size: 16))
                                Text(chord.name)
                                    .font(.system(size: 13, weight: .bold, design: .rounded))
                            }
                            .foregroundColor(selectedChord.id == chord.id ? .white : palette.title)
                            .frame(width: 74, height: 66)
                            .background(selectedChord.id == chord.id ? theme.accent : palette.cardFill,
                                        in: RoundedRectangle(cornerRadius: 18))
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(18)
        .appCardStyle()
    }

    private var measureSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("六线谱编辑")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            ForEach(measures.indices, id: \.self) { index in
                measureEditor(index: index)
            }
        }
    }

    private func measureEditor(index: Int) -> some View {
        let measure = measures[index]

        return VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("小节 \(index + 1)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(palette.muted)
                    Text(measure.chord.name)
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(theme.accent)
                }

                Spacer()

                Button {
                    vm.playChord(measure.chord)
                } label: {
                    Image(systemName: "play.fill")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(theme.accent, in: Circle())
                }
                .buttonStyle(.plain)
            }

            TextField("例如：副歌第 1 小节", text: binding(for: index, keyPath: \.title))
                .textFieldStyle(.plain)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.title)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(palette.softFill, in: RoundedRectangle(cornerRadius: 14))

            HStack(spacing: 10) {
                Button {
                    measures[index].chord = selectedChord
                } label: {
                    Text("替换为 \(selectedChord.name)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(theme.accent)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(theme.accent.opacity(0.12), in: Capsule())
                }
                .buttonStyle(.plain)

                Stepper(value: binding(for: index, keyPath: \.beats), in: 1...8) {
                    Text("\(measure.beats) 拍")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.title)
                }
                .labelsHidden()

                Text("\(measure.beats) 拍")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(palette.title)

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TabInsertTemplate.allCases) { template in
                        Button {
                            apply(template: template, to: index)
                        } label: {
                            Text(template.rawValue)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(palette.body)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(palette.softFill, in: Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            TextField("右手标记，例如：右手:   ↓     ↓     ↑     ↓", text: binding(for: index, keyPath: \.techniqueLabel))
                .textFieldStyle(.plain)
                .font(.system(size: 13, weight: .bold, design: .monospaced))
                .foregroundColor(theme.accent)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(theme.accent.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))

            VStack(spacing: 8) {
                ForEach(stringLabels.indices, id: \.self) { rowIndex in
                    TabStaffEditorRow(
                        label: stringLabels[rowIndex],
                        value: bindingForRow(measureIndex: index, rowIndex: rowIndex),
                        palette: palette
                    )
                }
            }

            HStack(spacing: 10) {
                Button {
                    measures.insert(measures[index], at: index + 1)
                } label: {
                    Text("复制小节")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(palette.title)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(palette.softFill, in: Capsule())
                }
                .buttonStyle(.plain)

                if measures.count > 1 {
                    Button {
                        measures.remove(at: index)
                    } label: {
                        Text("删除")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(Color(red: 0.69, green: 0.24, blue: 0.21))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color(red: 0.98, green: 0.91, blue: 0.89), in: Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .appCardStyle(cornerRadius: 24)
    }

    private var fullPreviewCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("整谱预览")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            ForEach(measures) { measure in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(measure.title)
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(palette.title)
                        Spacer()
                        Text(measure.chord.name)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accent)
                    }

                    Text(measure.techniqueLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accent)

                    VStack(alignment: .leading, spacing: 5) {
                        ForEach(stringLabels.indices, id: \.self) { rowIndex in
                            Text("\(stringLabels[rowIndex])|\(measure.rows[rowIndex])")
                                .font(.system(size: 14, weight: .medium, design: .monospaced))
                                .foregroundColor(palette.title)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    .padding(14)
                    .background(Color(red: 0.97, green: 0.96, blue: 0.92), in: RoundedRectangle(cornerRadius: 18))
                }
                .padding(16)
                .appCardStyle(cornerRadius: 22)
            }
        }
    }

    private func binding<T>(for index: Int, keyPath: WritableKeyPath<TabMeasure, T>) -> Binding<T> {
        Binding(
            get: { measures[index][keyPath: keyPath] },
            set: { measures[index][keyPath: keyPath] = $0 }
        )
    }

    private func bindingForRow(measureIndex: Int, rowIndex: Int) -> Binding<String> {
        Binding(
            get: { measures[measureIndex].rows[rowIndex] },
            set: { measures[measureIndex].rows[rowIndex] = $0 }
        )
    }

    private func makeMeasure(chord: Chord, template: TabInsertTemplate, title: String) -> TabMeasure {
        TabMeasure(
            title: title,
            chord: chord,
            beats: 4,
            techniqueLabel: template.techniqueLabel,
            rows: rows(for: chord, template: template)
        )
    }

    private func apply(template: TabInsertTemplate, to index: Int) {
        let chord = measures[index].chord
        measures[index].techniqueLabel = template.techniqueLabel
        measures[index].rows = rows(for: chord, template: template)
    }

    private func rows(for chord: Chord, template: TabInsertTemplate) -> [String] {
        let symbols = chord.frets.reversed().map(tabSymbol)

        switch template {
        case .blank:
            return Array(repeating: "------------------------", count: 6)
        case .downStrum:
            return symbols.map { symbol in
                "\(symbol)-----\(symbol)-----\(symbol)-----\(symbol)--"
            }
        case .arpeggio:
            return symbols.enumerated().map { index, symbol in
                arpeggioRow(symbol: symbol, position: index)
            }
        case .mutedGroove:
            return symbols.map { symbol in
                "\(symbol)--x---\(symbol)--x---\(symbol)-------"
            }
        }
    }

    private func tabSymbol(_ fret: Int) -> String {
        if fret < 0 { return "X" }
        if fret == 0 { return "0" }
        return "\(fret)"
    }

    private func arpeggioRow(symbol: String, position: Int) -> String {
        let leading = max(0, (5 - position) * 4)
        let trailing = max(0, 24 - leading - symbol.count)
        return String(repeating: "-", count: leading) + symbol + String(repeating: "-", count: trailing)
    }
}
