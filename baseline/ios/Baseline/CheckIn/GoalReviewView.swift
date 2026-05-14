import SwiftUI

struct GoalReviewView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text("Mark what you finished today. Non-negotiables are pinned—tap a row to toggle.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                HStack {
                    Text("Focus logged today")
                        .font(Theme.Typography.caption1())
                        .foregroundStyle(Theme.Colors.textMuted)
                    Spacer()
                    Text("\(viewModel.focusMinutesTotal) min")
                        .font(Theme.Typography.caption1())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )

                VStack(alignment: .leading, spacing: 0) {
                    ForEach(viewModel.goals) { goal in
                        Button {
                            viewModel.toggleGoal(id: goal.id)
                        } label: {
                            GoalRowView(
                                title: goal.title,
                                isNonNegotiable: goal.isNonNegotiable,
                                isDone: goal.completed,
                            )
                        }
                        .buttonStyle(.plain)
                        if goal.id != viewModel.goals.last?.id {
                            Divider().background(Theme.Colors.border)
                        }
                    }
                }
                .padding(Theme.Spacing.sm)
                .background(Theme.Colors.surface)
                .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                        .stroke(Theme.Colors.border, lineWidth: 1)
                )

                BaselineButton(title: "Continue to reflection") {
                    viewModel.goToReflection()
                }
                .padding(.top, Theme.Spacing.xs)
            }
            .padding(Theme.Spacing.sm)
        }
        .background(Theme.Colors.background)
    }
}
