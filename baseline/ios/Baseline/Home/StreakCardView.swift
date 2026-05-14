import SwiftUI

struct StreakCardView: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            HStack {
                Text("Streak")
                    .font(Theme.Typography.caption1())
                    .foregroundStyle(Theme.Colors.textSecondary)
                Spacer(minLength: 0)
                if viewModel.streakActive {
                    Text("Active")
                        .font(Theme.Typography.caption2())
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.horizontal, Theme.Spacing.xs)
                        .padding(.vertical, 4)
                        .background(Theme.Colors.accent.opacity(0.18))
                        .clipShape(Capsule())
                }
            }

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.sm) {
                StreakBadgeView(count: viewModel.streakCurrent)
                Text("best \(viewModel.streakMax)")
                    .font(Theme.Typography.subheadline())
                    .foregroundStyle(Theme.Colors.textMuted)
            }

            Text("Today counts when you finish your check-in—keep the chain honest, not perfect.")
                .font(Theme.Typography.footnote())
                .foregroundStyle(Theme.Colors.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Streak \(viewModel.streakCurrent) days, best \(viewModel.streakMax)")
    }
}
