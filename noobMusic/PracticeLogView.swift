import SwiftUI

// MARK: - Practice Log View
struct PracticeLogView: View {
    @ObservedObject var log: PracticeLogEngine
    @ObservedObject var themeEngine: ThemeEngine
    @Environment(\.dismiss) private var dismiss

    // Which month is shown (offset from today's month, 0 = current)
    @State private var monthOffset: Int = 0
    @State private var selectedDate: Date? = nil

    private var theme: AppTheme { themeEngine.current }

    // MARK: - Computed month info
    private var displayMonth: Date {
        Calendar.current.date(byAdding: .month, value: monthOffset, to: monthStart(Date()))!
    }
    private func monthStart(_ ref: Date) -> Date {
        let c = Calendar.current
        let comps = c.dateComponents([.year, .month], from: ref)
        return c.date(from: comps)!
    }
    private var monthYear: (Int, Int) {
        let c = Calendar.current
        return (c.component(.year, from: displayMonth),
                c.component(.month, from: displayMonth))
    }
    private var monthLabel: String {
        let f = DateFormatter()
        f.dateFormat = "yyyy 年 M 月"
        return f.string(from: displayMonth)
    }

    // MARK: - Body
    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.05, blue: 0.02),
                         Color(red: 0.14, green: 0.09, blue: 0.03)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                    .padding(.top, 12)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 18) {
                        todayCard
                            .padding(.horizontal, 20)

                        statsRow
                            .padding(.horizontal, 20)

                        calendarCard
                            .padding(.horizontal, 16)

                        if let date = selectedDate {
                            dayDetailCard(date: date)
                                .padding(.horizontal, 20)
                                .transition(.move(edge: .bottom).combined(with: .opacity))
                        }

                        legendRow
                            .padding(.horizontal, 20)
                            .padding(.bottom, 24)
                    }
                    .animation(.spring(response: 0.3), value: selectedDate)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Header
    private var headerBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("练习打卡")
                    .font(.system(size: 22, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text("坚持练习，每天进步")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.40))
            }
            Spacer()
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.70))
                    .padding(10)
                    .background(Color.white.opacity(0.10), in: Circle())
            }
        }
    }

    // MARK: - Today live card
    private var todayCard: some View {
        HStack(spacing: 16) {
            // Live timer ring
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.10), lineWidth: 6)
                    .frame(width: 72, height: 72)
                let level = log.heatLevel(for: Date())
                Circle()
                    .trim(from: 0, to: CGFloat(level) / 4.0)
                    .stroke(heatColor(level), style: StrokeStyle(lineWidth: 6, lineCap: .round))
                    .frame(width: 72, height: 72)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.5), value: level)
                VStack(spacing: 0) {
                    Text(log.isTracking ? "计时中" : "今天")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                    Text(log.todaySeconds.practiceTimeString)
                        .font(.system(size: 15, weight: .black, design: .monospaced))
                        .foregroundColor(log.isTracking ? theme.accent : .white)
                        .contentTransition(.numericText())
                }
            }

            VStack(alignment: .leading, spacing: 5) {
                Text(todayPracticeLabel)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
                Text("目标：30 分钟 · 已完成 \(Int(min(1.0, Double(log.todaySeconds) / 1800.0) * 100))%")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.45))

                // 30-min progress bar
                GeometryReader { g in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Color.white.opacity(0.10))
                            .frame(height: 5)
                        Capsule().fill(theme.accent)
                            .frame(width: g.size.width * CGFloat(min(1.0, Double(log.todaySeconds) / 1800.0)),
                                   height: 5)
                            .animation(.spring(response: 0.4), value: log.todaySeconds)
                    }
                }
                .frame(height: 5)
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(log.isTracking ? theme.accent.opacity(0.45) : Color.white.opacity(0.10),
                            lineWidth: 1.5))
        )
        .shadow(color: log.isTracking ? theme.glow.opacity(0.25) : .clear, radius: 12)
    }

    private var todayPracticeLabel: String {
        let secs = log.todaySeconds
        if secs == 0 { return "今天还没开始练习" }
        if secs < 300 { return "刚开始，继续加油！" }
        if secs < 900 { return "不错，状态来了！" }
        if secs < 1800 { return "练得挺好的！" }
        return "今天练习达标 🎉"
    }

    // MARK: - Stats Row
    private var statsRow: some View {
        let (yr, mo) = monthYear
        return HStack(spacing: 10) {
            statChip(value: "\(log.currentStreak)", unit: "天", label: "连续打卡", icon: "flame.fill", color: Color(red:1,green:0.5,blue:0.1))
            statChip(value: monthTotalLabel(yr: yr, mo: mo), unit: "", label: "本月时长", icon: "calendar", color: theme.accent)
            statChip(value: log.bestDaySeconds.practiceTimeString, unit: "", label: "最佳单日", icon: "trophy.fill", color: Color(red:1,green:0.8,blue:0.1))
        }
    }

    private func monthTotalLabel(yr: Int, mo: Int) -> String {
        let secs = log.monthTotal(year: yr, month: mo)
        if secs < 60 { return "\(secs)s" }
        return "\(secs / 60)m"
    }

    private func statChip(value: String, unit: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(color)
            HStack(alignment: .firstTextBaseline, spacing: 1) {
                Text(value)
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(color.opacity(0.20), lineWidth: 1))
        )
    }

    // MARK: - Calendar card
    private var calendarCard: some View {
        VStack(spacing: 10) {
            // Month nav
            HStack {
                Button { withAnimation { monthOffset -= 1 } } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.65))
                        .padding(8)
                        .background(Color.white.opacity(0.08), in: Circle())
                }
                Spacer()
                Text(monthLabel)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Spacer()
                Button {
                    withAnimation { monthOffset = min(monthOffset + 1, 0) }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(monthOffset < 0 ? .white.opacity(0.65) : .white.opacity(0.20))
                        .padding(8)
                        .background(Color.white.opacity(monthOffset < 0 ? 0.08 : 0.04), in: Circle())
                }
                .disabled(monthOffset >= 0)
            }
            .padding(.horizontal, 4)

            // Weekday headers
            HStack(spacing: 0) {
                ForEach(["日","一","二","三","四","五","六"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.30))
                        .frame(maxWidth: .infinity)
                }
            }

            // Day grid
            let weeks = calendarWeeks(for: displayMonth)
            ForEach(weeks.indices, id: \.self) { wi in
                HStack(spacing: 0) {
                    ForEach(weeks[wi].indices, id: \.self) { di in
                        if let date = weeks[wi][di] {
                            dayCell(date: date)
                        } else {
                            Color.clear.frame(maxWidth: .infinity, minHeight: 36)
                        }
                    }
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.05))
                .overlay(RoundedRectangle(cornerRadius: 18)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1))
        )
    }

    private func dayCell(date: Date) -> some View {
        let level   = log.heatLevel(for: date)
        let isToday = Calendar.current.isDateInToday(date)
        let isFuture = date > Date()
        let isSelected = selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
        let dayNum  = Calendar.current.component(.day, from: date)

        return Button {
            guard !isFuture else { return }
            withAnimation(.spring(response: 0.25)) {
                selectedDate = isSelected ? nil : date
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    RoundedRectangle(cornerRadius: 7)
                        .fill(isFuture ? Color.clear : heatColor(level).opacity(level == 0 ? 0.06 : 0.85))
                        .frame(height: 30)
                        .overlay(
                            RoundedRectangle(cornerRadius: 7)
                                .stroke(
                                    isToday   ? theme.accent :
                                    isSelected ? Color.white.opacity(0.80) :
                                                 Color.clear,
                                    lineWidth: isToday || isSelected ? 1.5 : 0
                                )
                        )

                    Text("\(dayNum)")
                        .font(.system(size: 12, weight: isToday ? .black : .medium))
                        .foregroundColor(
                            isFuture ? .white.opacity(0.15) :
                            level > 0 ? .white :
                            isToday  ? theme.accent :
                                       .white.opacity(0.45)
                        )
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 3)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Day detail card
    private func dayDetailCard(date: Date) -> some View {
        let secs  = log.seconds(for: date)
        let level = log.heatLevel(for: date)
        let f     = DateFormatter()
        _ = { f.dateFormat = "M 月 d 日 EEEE"; f.locale = Locale(identifier: "zh_CN") }()
        let label = f.string(from: date)

        return HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 6)
                .fill(heatColor(level).opacity(level == 0 ? 0.15 : 0.85))
                .frame(width: 6)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white)
                Text(secs == 0 ? "当天未练习" : "练习了 \(secs.practiceMinutesString)")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.55))
            }
            Spacer()
            Text(heatLevelLabel(level))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(level == 0 ? .white.opacity(0.30) : heatColor(level))
                .padding(.horizontal, 10).padding(.vertical, 4)
                .background(heatColor(level).opacity(level == 0 ? 0.06 : 0.18), in: Capsule())
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(RoundedRectangle(cornerRadius: 14)
                    .stroke(heatColor(level).opacity(0.25), lineWidth: 1))
        )
    }

    // MARK: - Legend
    private var legendRow: some View {
        HStack(spacing: 8) {
            Text("练习时长")
                .font(.system(size: 10))
                .foregroundColor(.white.opacity(0.35))
            Spacer()
            ForEach(0..<5) { level in
                HStack(spacing: 3) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(heatColor(level).opacity(level == 0 ? 0.12 : 0.85))
                        .frame(width: 14, height: 14)
                    Text(legendLabel(level))
                        .font(.system(size: 9))
                        .foregroundColor(.white.opacity(0.35))
                }
            }
        }
    }

    // MARK: - Heat color
    func heatColor(_ level: Int) -> Color {
        switch level {
        case 0: return Color.white
        case 1: return theme.accent.opacity(0.35)
        case 2: return theme.accent.opacity(0.60)
        case 3: return theme.accent.opacity(0.82)
        default: return theme.accent
        }
    }

    private func legendLabel(_ level: Int) -> String {
        switch level {
        case 0: return "无"
        case 1: return "<5m"
        case 2: return "5-15m"
        case 3: return "15-30m"
        default: return "30m+"
        }
    }

    private func heatLevelLabel(_ level: Int) -> String {
        switch level {
        case 0: return "未练习"
        case 1: return "入门"
        case 2: return "不错"
        case 3: return "良好"
        default: return "优秀 🔥"
        }
    }

    // MARK: - Calendar logic
    /// Returns a 2D array of optional Dates: 6 rows × 7 columns (nil = padding cell)
    private func calendarWeeks(for monthDate: Date) -> [[Date?]] {
        let cal = Calendar.current
        var comps = cal.dateComponents([.year, .month], from: monthDate)
        comps.day = 1
        guard let firstDay = cal.date(from: comps) else { return [] }

        // Weekday of first day (0 = Sun)
        let firstWeekday = (cal.component(.weekday, from: firstDay) - 1 + 7) % 7
        let daysInMonth  = cal.range(of: .day, in: .month, for: firstDay)!.count

        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for d in 1...daysInMonth {
            comps.day = d
            days.append(cal.date(from: comps))
        }
        // Pad to full weeks
        while days.count % 7 != 0 { days.append(nil) }

        return stride(from: 0, to: days.count, by: 7).map { Array(days[$0..<$0+7]) }
    }
}


