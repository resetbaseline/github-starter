import SwiftUI

struct DayResultView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                Text(viewModel.dayStatusHeadline)
                    .font(Theme.Typography.title1())
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.dayStatusBody)
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                summaryRow(title: "Goals marked done", value: "\(viewModel.goalsCompletedCount) / \(viewModel.goals.count)")
                summaryRow(title: "Reflections with text", value: "\(viewModel.reflectionAnswerCount)")
                summaryRow(title: "Focus minutes (today)", value: "\(viewModel.focusMinutesTotal)")

                streakCard

                if viewModel.computedDayStatus == "light" {
                    Toggle(isOn: Binding(
                        get: { viewModel.useStreakFreeze },
                        set: { viewModel.setStreakFreeze($0) },
                    )) {
                        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                            Text("Use streak freeze")
                                .font(Theme.Typography.headline())
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text("If you have a freeze available, this keeps your current streak number instead of resetting.")
                                .font(Theme.Typography.footnote())
                                .foregroundStyle(Theme.Colors.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.Colors.accent)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                }

                if !viewModel.tomorrowIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Tomorrow")
                            .font(Theme.Typography.caption1())
                            .foregroundStyle(Theme.Colors.textSecondary)
                        Text(viewModel.tomorrowIntention)
                            .font(Theme.Typography.callout())
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(Theme.Spacing.sm)
                    .background(Theme.Colors.surface)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                            .stroke(Theme.Colors.border, lineWidth: 1)
                    )
                }

                Text("Next: the process-checkin Edge Function will persist this day, update streaks, and queue coach notes.")
                    .font(Theme.Typography.caption2())
                    .foregroundStyle(Theme.Colors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                BaselineButton(title: "Done") {
                    viewModel.completeCheckInAndReset()
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .padding(Theme.Spacing.sm)
        }
        .background(Theme.Colors.background)
    }

    private func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(Theme.Typography.subheadline())
                .foregroundStyle(Theme.Colors.textSecondary)
            Spacer(minLength: Theme.Spacing.sm)
            Text(value)
                .font(Theme.Typography.subheadline())
                .foregroundStyle(Theme.Colors.textPrimary)
        }
        .padding(.vertical, Theme.Spacing.xs)
    }

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("Streak update")
                .font(Theme.Typography.caption1())
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(alignment: .center, spacing: Theme.Spacing.md) {
                VStack(spacing: Theme.Spacing.xs) {
                    Text("Before")
                        .font(Theme.Typography.caption2())
                        .foregroundStyle(Theme.Colors.textMuted)
                    Text("\(viewModel.streakBefore)")
                        .font(Theme.Typography.title2())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)

                Image(systemName: "arrow.right")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)

                VStack(spacing: Theme.Spacing.xs) {
                    Text("After")
                        .font(Theme.Typography.caption2())
                        .foregroundStyle(Theme.Colors.textMuted)
                    Text("\(viewModel.streakAfter)")
                        .font(Theme.Typography.title2())
                        .foregroundStyle(Theme.Colors.textPrimary)
                }
                .frame(maxWidth: .infinity)
            }

            Text(viewModel.streakChangeDescription)
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
        .accessibilityLabel("Streak before \(viewModel.streakBefore), after \(viewModel.streakAfter)")
    }
}
