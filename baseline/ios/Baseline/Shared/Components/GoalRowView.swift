import SwiftUI

struct GoalRowView: View {
    let title: String
    let isNonNegotiable: Bool
    let isDone: Bool

    init(title: String, isNonNegotiable: Bool = false, isDone: Bool) {
        self.title = title
        self.isNonNegotiable = isNonNegotiable
        self.isDone = isDone
    }

    var body: some View {
        HStack(alignment: .top, spacing: Theme.Spacing.sm) {
            Image(systemName: isDone ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(isDone ? Theme.Colors.accent : Theme.Colors.textMuted)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                HStack(spacing: Theme.Spacing.xs) {
                    Text(title)
                        .font(Theme.Typography.body())
                        .foregroundStyle(isDone ? Theme.Colors.textSecondary : Theme.Colors.textPrimary)
                        .strikethrough(isDone, color: Theme.Colors.textMuted)

                    if isNonNegotiable {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(Theme.Colors.accent)
                            .accessibilityLabel("Non-negotiable")
                    }
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, Theme.Spacing.xs)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLine)
    }

    private var accessibilityLine: String {
        let nn = isNonNegotiable ? ", non-negotiable" : ""
        let state = isDone ? "completed" : "not completed"
        return "\(title)\(nn), \(state)"
    }
}
