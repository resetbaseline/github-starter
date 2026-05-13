import SwiftUI

struct GoalRowView: View {
    let title: String
    let isDone: Bool

    var body: some View {
        HStack(spacing: Theme.Spacing.sm) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isDone ? Theme.Colors.accent : Theme.Colors.textMuted)
            Text(title)
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }
}
