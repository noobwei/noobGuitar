import SwiftUI

struct SurfacePalette {
    let backgroundTop = Color(red: 0.95, green: 0.94, blue: 0.90)
    let backgroundBottom = Color(red: 0.87, green: 0.84, blue: 0.77)
    let cardFill = Color.white.opacity(0.88)
    let softFill = Color(red: 0.96, green: 0.93, blue: 0.88)
    let title = Color(red: 0.15, green: 0.11, blue: 0.08)
    let body = Color(red: 0.33, green: 0.27, blue: 0.20)
    let muted = Color(red: 0.54, green: 0.46, blue: 0.36)
    let shadow = Color.black.opacity(0.05)
}

extension View {
    func appCardStyle(cornerRadius: CGFloat = 24) -> some View {
        background(
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(SurfacePalette().cardFill)
                .shadow(color: SurfacePalette().shadow, radius: 14, x: 0, y: 8)
        )
    }

    func appBackButtonStyle() -> some View {
        font(.system(size: 14, weight: .bold))
            .foregroundColor(SurfacePalette().body)
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(Color.white.opacity(0.86), in: Capsule())
    }
}
