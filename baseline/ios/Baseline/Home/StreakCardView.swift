import SwiftUI

struct StreakPillView: View {
    let count: Int

    var body: some View {
        HStack(spacing: 4) {
            Text("🔥")
            Text("\(count)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.Colors.accent)
            Text("day streak")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.accent)
        }
        .padding(.vertical, 5)
        .padding(.horizontal, 10)
        .background(Color(hex: "#1A1228"))
        .clipShape(Capsule())
        .overlay(
            Capsule()
                .stroke(Color(hex: "#2D1F4A"), lineWidth: 0.5),
        )
        .accessibilityLabel("\(count) day streak")
    }
}
