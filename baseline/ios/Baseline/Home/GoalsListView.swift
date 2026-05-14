import SwiftUI

struct GoalsListView: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack(alignment: .firstTextBaseline) {
                Text("Today's goals")
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer(minLength: 0)
                Text("\(viewModel.goalsCompleted)/\(viewModel.goalsTotal)")
                    .font(Theme.Typography.subheadline())
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            if viewModel.goals.isEmpty {
                ContentUnavailableView(
                    "No goals yet",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Add goals for today from your planner flow when it is wired to Supabase."),
                )
                .foregroundStyle(Theme.Colors.textSecondary)
                .padding(.vertical, Theme.Spacing.md)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.goals) { goal in
                        GoalRowView(
                            title: goal.title,
                            isNonNegotiable: goal.isNonNegotiable,
                            isDone: goal.isCompleted,
                        )
                        if goal.id != viewModel.goals.last?.id {
                            Divider()
                                .background(Theme.Colors.border)
                        }
                    }
                }
            }
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
