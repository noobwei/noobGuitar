import SwiftUI

private struct GuideTheorySection: Identifiable {
    let id = UUID()
    let title: String
    let summary: String
    let points: [String]
}

private struct GuideTabExample: Identifiable {
    let id = UUID()
    let title: String
    let topLabel: String
    let rows: [String]
    let footnote: String
}

private struct GuideReferenceCard: Identifiable {
    let id = UUID()
    let title: String
    let value: String
    let note: String
}

private struct GuideRoadmapStep: Identifiable {
    let id = UUID()
    let title: String
    let detail: String
}

private struct TabStaffView: View {
    let rows: [String]

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            ForEach(rows, id: \.self) { row in
                Text(row)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(Color(red: 0.19, green: 0.14, blue: 0.10))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
        .background(Color(red: 0.97, green: 0.96, blue: 0.92), in: RoundedRectangle(cornerRadius: 18))
    }
}

struct GuidebookView: View {
    @ObservedObject var themeEngine: ThemeEngine
    @Environment(\.dismiss) private var dismiss

    private let palette = SurfacePalette()
    private var theme: AppTheme { themeEngine.current }

    private let sections: [GuideTheorySection] = [
        GuideTheorySection(
            title: "六线谱怎么看",
            summary: "六线谱的六条线对应六根弦，最上面是 1 弦高音 e，最下面是 6 弦低音 E。",
            points: [
                "线上的数字表示左手按第几品，`0` 表示空弦，`X` 表示不弹这根弦。",
                "数字上下同时出现，表示这些音需要一起拨或一起扫。",
                "从左到右就是时间顺序，所以先看横向，再看每个数字在哪条线上。"
            ]
        ),
        GuideTheorySection(
            title: "基础乐理",
            summary: "初学阶段只要先抓住音名、节拍和和弦构成，不需要一开始就学得太深。",
            points: [
                "十二个音循环是 C C# D D# E F F# G G# A A# B，12 个半音后回到同名高八度。",
                "4/4 拍可以理解成每小节四拍，节拍器每响一次通常算一拍。",
                "大三和弦通常由根音、三音、五音组成，例如 C 和弦包含 C、E、G。"
            ]
        ),
        GuideTheorySection(
            title: "右手技巧记号",
            summary: "写谱时不只写和弦名，还要写清楚右手动作，不然回看时信息不够。",
            points: [
                "`↓` 表示顺扫，从低音弦向高音弦。",
                "`↑` 表示逆扫，从高音弦向低音弦。",
                "`x` 表示制音扫弦，强调节奏型。",
                "`P` 表示分解拨弦，可以理解成按顺序拨响和弦里的音。"
            ]
        ),
        GuideTheorySection(
            title: "读谱顺序",
            summary: "先看节奏，再看右手动作，最后确认左手按法，效率更高。",
            points: [
                "如果一小节里有很多数字，先找拍点，再确定哪些是同拍同时出现的音。",
                "练新谱时先用 50 到 70 BPM，确认每一拍都知道该扫还是该拨。",
                "把难点拆成 1 小节或半小节重复，比整段从头弹到底更有效。"
            ]
        )
    ]

    private let examples: [GuideTabExample] = [
        GuideTabExample(
            title: "C 和弦顺扫",
            topLabel: "右手:   ↓     ↓     ↑     ↓",
            rows: [
                "e|--0-----------0-----------0-----------0--",
                "B|--1-----------1-----------1-----------1--",
                "G|--0-----------0-----------0-----------0--",
                "D|--2-----------2-----------2-----------2--",
                "A|--3-----------3-----------3-----------3--",
                "E|--X-----------X-----------X-----------X--"
            ],
            footnote: "这个例子表示保持 C 和弦，每拍做一次清晰扫弦。"
        ),
        GuideTabExample(
            title: "分解拨弦示例",
            topLabel: "右手:   P(5-4-3-2)    P(5-4-3-2)",
            rows: [
                "e|-----------------------------------------",
                "B|--------1-----------------1--------------",
                "G|-----0-----------------0-----------------",
                "D|--2-----------------2--------------------",
                "A|3-----------------3----------------------",
                "E|-----------------------------------------"
            ],
            footnote: "从 A 弦开始往上拨，适合练右手稳定性。"
        ),
        GuideTabExample(
            title: "制音节奏型",
            topLabel: "右手:   ↓     x     ↑     x",
            rows: [
                "e|--0-----x-----0-----x--------------------",
                "B|--1-----x-----1-----x--------------------",
                "G|--0-----x-----0-----x--------------------",
                "D|--2-----x-----2-----x--------------------",
                "A|--3-----x-----3-----x--------------------",
                "E|--X-----x-----X-----x--------------------"
            ],
            footnote: "`x` 不是按某个品，而是右手做制音扫弦，听起来更像节奏击打。"
        )
    ]

    private let references: [GuideReferenceCard] = [
        GuideReferenceCard(title: "和弦图", value: "纵向看弦，横向看品", note: "黑点表示按住的位置，最上方的 X / O 表示不弹或空弦。"),
        GuideReferenceCard(title: "六线谱", value: "每条线就是一根弦", note: "数字出现在哪条线上，就弹哪根弦的对应品位。"),
        GuideReferenceCard(title: "节拍", value: "先找拍点再找动作", note: "4/4 拍里一小节通常数 1 2 3 4，再决定每拍是扫还是拨。"),
        GuideReferenceCard(title: "右手记号", value: "↓ ↑ x P", note: "顺扫、逆扫、制音、分解拨弦，是初学最常见的一组符号。")
    ]

    private let roadmap: [GuideRoadmapStep] = [
        GuideRoadmapStep(title: "先认弦和品位", detail: "先把 6 根空弦名字和 1 到 5 品的位置认熟，不急着上速度。"),
        GuideRoadmapStep(title: "再练常用开放和弦", detail: "优先练 C、G、Am、Em、D 这类高频和弦，先保证每根弦都能响。"),
        GuideRoadmapStep(title: "加入节拍器", detail: "从 50 到 70 BPM 开始，每拍只做一个明确动作，不要边弹边猜。"),
        GuideRoadmapStep(title: "最后再练切换和节奏型", detail: "等单个和弦稳定后，再把两个和弦连起来练，并加入 `↓ ↑ x` 这种右手变化。")
    ]

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
                    introCard
                    quickReferenceSection
                    theorySection
                    roadmapSection
                    tabExamplesSection
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 28)
            }
        }
        .preferredColorScheme(.light)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 6) {
                Text("Guidebook")
                    .font(.system(size: 28, weight: .black, design: .rounded))
                    .foregroundColor(palette.title)
                Text("六线谱、简单乐理和右手记号。")
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

    private var introCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("你需要先会读，再会练")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)
            Text("这个页面不只是说明文字，而是给你一套最基础的读谱入口。先知道六线谱每一条线代表什么，再把节拍、和弦与右手动作连起来。")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(palette.body)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(theme.accent.opacity(0.14))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(theme.accent.opacity(0.24), lineWidth: 1)
                )
        )
    }

    private var theorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("理论知识")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            ForEach(sections) { section in
                sectionCard(section)
            }
        }
    }

    private var quickReferenceSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("读谱速查")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(references) { item in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(item.title)
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(palette.muted)
                        Text(item.value)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(theme.accent)
                        Text(item.note)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(palette.body)
                    }
                    .frame(maxWidth: .infinity, minHeight: 134, alignment: .topLeading)
                    .padding(16)
                    .appCardStyle(cornerRadius: 22)
                }
            }
        }
    }

    private func sectionCard(_ section: GuideTheorySection) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(section.title)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            Text(section.summary)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(palette.body)

            ForEach(section.points, id: \.self) { point in
                HStack(alignment: .top, spacing: 10) {
                    Circle()
                        .fill(theme.accent)
                        .frame(width: 7, height: 7)
                        .padding(.top, 6)
                    Text(point)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(palette.body)
                }
            }
        }
        .padding(18)
        .appCardStyle()
    }

    private var tabExamplesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("六线谱示例")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            ForEach(examples) { example in
                VStack(alignment: .leading, spacing: 12) {
                    Text(example.title)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(palette.title)
                    Text(example.topLabel)
                        .font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(theme.accent)
                    TabStaffView(rows: example.rows)
                    Text(example.footnote)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(palette.body)
                }
                .padding(18)
                .appCardStyle()
            }
        }
    }

    private var roadmapSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("初学路线")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(palette.title)

            ForEach(Array(roadmap.enumerated()), id: \.element.id) { index, step in
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(theme.accent.opacity(0.16))
                            .frame(width: 34, height: 34)
                        Text("\(index + 1)")
                            .font(.system(size: 14, weight: .black, design: .rounded))
                            .foregroundColor(theme.accent)
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(step.title)
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(palette.title)
                        Text(step.detail)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(palette.body)
                    }

                    Spacer()
                }
                .padding(18)
                .appCardStyle(cornerRadius: 24)
            }
        }
    }
}
