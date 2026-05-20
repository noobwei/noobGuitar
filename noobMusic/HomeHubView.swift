import SwiftUI


private enum HomeDestination: String, Identifiable {
    case workbench
    case challenge
    case composer
    case guidebook
    case practiceLog

    var id: String { rawValue }
}

private struct HomeFeatureCard: Identifiable {
    let id: HomeDestination
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
}

struct HomeHubView: View {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var themeEngine = ThemeEngine()
    @StateObject private var practiceLog = PracticeLogEngine()
    @State private var destination: HomeDestination?

    private var theme: AppTheme { themeEngine.current }
    private var themeLabel: String { theme.name.split(separator: " ").last.map(String.init) ?? theme.name }

    private var cards: [HomeFeatureCard] {
        [
            HomeFeatureCard(
                id: .challenge,
                title: "轻打卡练习",
                subtitle: "选和弦类型直接开练，支持 BPM 和手动 Pass。",
                symbol: "bolt.heart.fill",
                accent: theme.accent
            ),
            HomeFeatureCard(
                id: .workbench,
                title: "练习台",
                subtitle: "指板、和弦库、节拍器、监听和扫弦练习都在这里。",
                symbol: "guitars.fill",
                accent: theme.accent2
            ),
            HomeFeatureCard(
                id: .composer,
                title: "谱本",
                subtitle: "写自己的和弦卡片谱，标记右手技巧并回放示范。",
                symbol: "square.and.pencil",
                accent: Color(red: 0.45, green: 0.82, blue: 0.52)
            ),
            HomeFeatureCard(
                id: .guidebook,
                title: "Guidebook",
                subtitle: "面向初学者的右手技巧、练习顺序和符号说明。",
                symbol: "book.closed.fill",
                accent: Color(red: 0.96, green: 0.72, blue: 0.26)
            )
        ]
    }

    var body: some View {
        NavigationStack {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.97, green: 0.95, blue: 0.90),
                        Color(red: 0.91, green: 0.88, blue: 0.82)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 18) {
                        heroSection
                        streakSection
                        featureGrid
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 18)
                    .padding(.bottom, 28)
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.light)
        .onAppear { practiceLog.startTracking() }
        .fullScreenCover(item: $destination) { target in
            switch target {
            case .workbench:
                ContentView(themeEngine: themeEngine, practiceLog: practiceLog)
            case .challenge:
                DailyChordChallengeView(themeEngine: themeEngine)
            case .composer:
                TabComposerView(themeEngine: themeEngine)
            case .guidebook:
                GuidebookView(themeEngine: themeEngine)
            case .practiceLog:
                PracticeLogView(log: practiceLog, themeEngine: themeEngine)
            }
        }
    }

    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Noob Music")
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundColor(Color(red: 0.15, green: 0.11, blue: 0.07))
                    Text("吉他练习、谱本和教学入口。")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 0.32, green: 0.26, blue: 0.18))
                }

                Spacer()

                Button {
                    destination = .practiceLog
                } label: {
                    Image(systemName: "calendar.badge.clock")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(theme.accent)
                        .padding(12)
                        .background(Color.white.opacity(0.86), in: Circle())
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                statPill(title: "今日", value: practiceLog.todaySeconds.practiceTimeString)
                statPill(title: "连续", value: "\(practiceLog.currentStreak) 天")
                statPill(title: "主题", value: themeLabel)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 28)
                .fill(Color.white.opacity(0.84))
                .overlay(
                    RoundedRectangle(cornerRadius: 28)
                        .stroke(theme.accent.opacity(0.16), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.06), radius: 18, x: 0, y: 10)
        )
    }

    private func statPill(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(Color(red: 0.52, green: 0.44, blue: 0.34))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(Color(red: 0.18, green: 0.13, blue: 0.09))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(Color(red: 0.96, green: 0.93, blue: 0.88), in: RoundedRectangle(cornerRadius: 18))
    }

    private var streakSection: some View {
        Button {
            destination = .challenge
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(theme.accent.opacity(0.18))
                        .frame(width: 56, height: 56)
                    Text("\(min(practiceLog.currentStreak, 99))")
                        .font(.system(size: 22, weight: .black, design: .rounded))
                        .foregroundColor(theme.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("快速开始")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Color(red: 0.16, green: 0.11, blue: 0.08))
                    Text("直接进入轻打卡练习。")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 0.40, green: 0.33, blue: 0.25))
                }

                Spacer()

                Image(systemName: "arrow.right")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(theme.accent)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 0.20, green: 0.16, blue: 0.12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(theme.accent.opacity(0.40), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }

    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 14) {
            ForEach(cards) { card in
                Button {
                    destination = card.id
                } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        Image(systemName: card.symbol)
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(card.accent)
                            .frame(width: 44, height: 44)
                            .background(card.accent.opacity(0.14), in: RoundedRectangle(cornerRadius: 14))

                        VStack(alignment: .leading, spacing: 5) {
                            Text(card.title)
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.16, green: 0.11, blue: 0.08))
                            Text(card.subtitle)
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(Color(red: 0.40, green: 0.33, blue: 0.25))
                                .fixedSize(horizontal: false, vertical: true)
                        }

                        Spacer(minLength: 0)
                    }
                    .frame(maxWidth: .infinity, minHeight: 162, alignment: .topLeading)
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 24)
                            .fill(Color.white.opacity(0.88))
                            .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 8)
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }

}
