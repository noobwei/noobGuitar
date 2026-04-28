import Foundation
import Combine
import SwiftUI

// MARK: - Practice Log Engine
// Tracks daily practice time (in seconds), persists to UserDefaults,
// and exposes helpers for the calendar heat-map view.
final class PracticeLogEngine: ObservableObject {

    // ── Persisted data ─────────────────────────────────────────────────
    // Key: "yyyy-MM-dd"  Value: cumulative seconds practiced that day
    @Published private(set) var log: [String: Int] = [:]

    // ── Live session ───────────────────────────────────────────────────
    @Published private(set) var todaySeconds: Int = 0
    @Published private(set) var isTracking:   Bool = false

    private var sessionStart: Date?
    private var ticker: AnyCancellable?
    private let udKey = "practice_log_v1"

    // MARK: - Init
    init() { load() }

    // MARK: - Tracking API

    func startTracking() {
        guard !isTracking else { return }
        isTracking   = true
        sessionStart = Date()
        todaySeconds = log[todayKey] ?? 0

        ticker = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, let start = self.sessionStart else { return }
                let base = self.log[self.todayKey] ?? 0
                self.todaySeconds = base + Int(Date().timeIntervalSince(start))
            }
    }

    func stopTracking() {
        guard isTracking, let start = sessionStart else { return }
        ticker?.cancel(); ticker = nil
        isTracking = false

        let elapsed = max(0, Int(Date().timeIntervalSince(start)))
        if elapsed > 0 {
            log[todayKey, default: 0] += elapsed
            todaySeconds = log[todayKey] ?? 0
            save()
        }
        sessionStart = nil
    }

    // MARK: - Query helpers

    var todayKey: String { dateKey(Date()) }

    func dateKey(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    /// Seconds practiced on a given date (including live session for today).
    func seconds(for date: Date) -> Int {
        let key = dateKey(date)
        let stored = log[key] ?? 0
        // Add live elapsed for today
        if key == todayKey, isTracking, let start = sessionStart {
            return stored + Int(Date().timeIntervalSince(start))
        }
        return stored
    }

    /// Heat level 0–4 for a date (used to pick color intensity).
    func heatLevel(for date: Date) -> Int {
        let secs = seconds(for: date)
        switch secs {
        case 0:          return 0
        case 1..<300:    return 1   // < 5 min
        case 300..<900:  return 2   // 5–15 min
        case 900..<1800: return 3   // 15–30 min
        default:         return 4   // 30+ min
        }
    }

    /// Total seconds this month.
    func monthTotal(year: Int, month: Int) -> Int {
        let prefix = String(format: "%04d-%02d-", year, month)
        return log.filter { $0.key.hasPrefix(prefix) }.values.reduce(0, +)
    }

    /// Current consecutive-day streak (ending today or yesterday).
    var currentStreak: Int {
        var streak = 0
        var cursor = Calendar.current.startOfDay(for: Date())
        // If today has no practice yet, start checking from yesterday
        if (log[dateKey(cursor)] ?? 0) == 0 {
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)!
        }
        while (log[dateKey(cursor)] ?? 0) > 0 {
            streak += 1
            cursor = Calendar.current.date(byAdding: .day, value: -1, to: cursor)!
        }
        return streak
    }

    /// Best single-day seconds ever.
    var bestDaySeconds: Int { log.values.max() ?? 0 }

    // MARK: - Persistence
    private func save() {
        if let data = try? JSONEncoder().encode(log) {
            UserDefaults.standard.set(data, forKey: udKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: udKey),
              let decoded = try? JSONDecoder().decode([String: Int].self, from: data)
        else { return }
        log = decoded
        todaySeconds = log[todayKey] ?? 0
    }
}

// MARK: - Formatting helpers
extension Int {
    /// Formats seconds as "mm:ss" or "Xh Ym".
    var practiceTimeString: String {
        if self < 3600 {
            return String(format: "%d:%02d", self / 60, self % 60)
        } else {
            return "\(self / 3600)h \((self % 3600) / 60)m"
        }
    }
    var practiceMinutesString: String {
        if self == 0 { return "0 分钟" }
        if self < 60  { return "\(self) 秒" }
        let m = self / 60
        let s = self % 60
        return s == 0 ? "\(m) 分钟" : "\(m) 分 \(s) 秒"
    }
}
