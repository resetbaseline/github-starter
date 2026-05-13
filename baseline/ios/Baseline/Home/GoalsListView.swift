import SwiftUI

struct GoalsListView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Goals")
                .font(Theme.Typography.headline())
                .foregroundStyle(Theme.Colors.textPrimary)
            GoalRowView(title: "First goal", isDone: false)
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
