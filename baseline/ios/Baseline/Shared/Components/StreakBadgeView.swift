import SwiftUI

struct StreakBadgeView: View {
    let count: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.xs) {
            Image(systemName: "flame.fill")
                .foregroundStyle(Theme.Colors.accent)
            Text("\(count)")
                .font(Theme.Typography.title3())
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}
