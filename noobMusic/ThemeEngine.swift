import SwiftUI
import Combine

// MARK: - App Theme
struct AppTheme: Identifiable, Equatable {
    let id        : String
    let name      : String
    let accent    : Color      // primary accent
    let accent2   : Color      // secondary / highlight
    let glow      : Color      // shadow glow
    let boardTint : Color      // fretboard overlay tint (subtle)

    static func == (lhs: AppTheme, rhs: AppTheme) -> Bool { lhs.id == rhs.id }
}

extension AppTheme {
    // ── Presets ────────────────────────────────────────────────────────
    static let presets: [AppTheme] = [
        AppTheme(
            id: "orange",
            name: "🎸 原木橙",
            accent:    Color(red: 1.00, green: 0.55, blue: 0.05),
            accent2:   Color(red: 1.00, green: 0.75, blue: 0.25),
            glow:      Color(red: 1.00, green: 0.55, blue: 0.05),
            boardTint: Color(red: 0.60, green: 0.35, blue: 0.10).opacity(0.08)
        ),
        AppTheme(
            id: "blue",
            name: "💻 极客蓝",
            accent:    Color(red: 0.20, green: 0.60, blue: 1.00),
            accent2:   Color(red: 0.45, green: 0.80, blue: 1.00),
            glow:      Color(red: 0.20, green: 0.60, blue: 1.00),
            boardTint: Color(red: 0.10, green: 0.30, blue: 0.65).opacity(0.08)
        ),
        AppTheme(
            id: "purple",
            name: "🌌 霓虹紫",
            accent:    Color(red: 0.75, green: 0.20, blue: 1.00),
            accent2:   Color(red: 0.90, green: 0.55, blue: 1.00),
            glow:      Color(red: 0.75, green: 0.20, blue: 1.00),
            boardTint: Color(red: 0.40, green: 0.10, blue: 0.60).opacity(0.08)
        ),
        AppTheme(
            id: "green",
            name: "🌿 清新绿",
            accent:    Color(red: 0.15, green: 0.82, blue: 0.45),
            accent2:   Color(red: 0.40, green: 0.95, blue: 0.65),
            glow:      Color(red: 0.15, green: 0.82, blue: 0.45),
            boardTint: Color(red: 0.05, green: 0.45, blue: 0.20).opacity(0.08)
        ),
        AppTheme(
            id: "rose",
            name: "🌸 玫瑰红",
            accent:    Color(red: 1.00, green: 0.25, blue: 0.50),
            accent2:   Color(red: 1.00, green: 0.55, blue: 0.70),
            glow:      Color(red: 1.00, green: 0.25, blue: 0.50),
            boardTint: Color(red: 0.60, green: 0.10, blue: 0.25).opacity(0.08)
        ),
    ]

    static var `default`: AppTheme { presets[0] }

    static func by(id: String) -> AppTheme {
        presets.first { $0.id == id } ?? .default
    }
}

// MARK: - Theme Engine (persists selection)
final class ThemeEngine: ObservableObject {
    @Published var current: AppTheme {
        didSet { UserDefaults.standard.set(current.id, forKey: "app_theme_id") }
    }

    init() {
        let saved = UserDefaults.standard.string(forKey: "app_theme_id") ?? "orange"
        current = AppTheme.by(id: saved)
    }

    func select(_ theme: AppTheme) {
        withAnimation(.easeInOut(duration: 0.25)) { current = theme }
    }
}

// MARK: - Environment Key so any child view can read the theme
private struct ThemeKey: EnvironmentKey {
    static let defaultValue: AppTheme = .default
}

extension EnvironmentValues {
    var theme: AppTheme {
        get { self[ThemeKey.self] }
        set { self[ThemeKey.self] = newValue }
    }
}
