import SwiftUI

struct OnboardingSetupView: View {
    @EnvironmentObject private var auth: AuthManager
    @State private var displayName: String = ""

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text(OnboardingViewModel.stepLabel(forStaticPage: 4))
                    .font(Theme.Typography.caption1())
                    .foregroundStyle(Theme.Colors.textMuted)

                Text("Almost there")
                    .font(Theme.Typography.title1())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("We’ll use this for greetings in the app. You can change it later in Profile.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("What should we call you?")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)

                    TextField("Name (optional)", text: $displayName)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Time zone")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text(TimeZone.current.identifier)
                        .font(Theme.Typography.callout())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Schedules and day boundaries follow your device time zone. You can adjust in Profile when travel mode ships.")
                        .font(Theme.Typography.footnote())
                        .foregroundStyle(Theme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                BaselineButton(title: "Get started") {
                    auth.completeOnboarding(preferredName: trimmedName.isEmpty ? nil : trimmedName)
                }
                .padding(.top, Theme.Spacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }
}
