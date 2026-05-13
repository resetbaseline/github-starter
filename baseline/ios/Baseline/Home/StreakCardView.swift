import SwiftUI

struct StreakCardView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Streak")
                .font(Theme.Typography.caption1())
                .foregroundStyle(Theme.Colors.textSecondary)
            StreakBadgeView(count: 0)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
    }
}
