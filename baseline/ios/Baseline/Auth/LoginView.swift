import SwiftUI

struct LoginView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        VStack(spacing: Theme.Spacing.lg) {
            Spacer(minLength: Theme.Spacing.xl)

            Circle()
                .fill(Theme.Logo.color)
                .frame(width: Theme.Logo.diameter, height: Theme.Logo.diameter)

            Text("Baseline")
                .font(Theme.Typography.title1())
                .foregroundStyle(Theme.Colors.textPrimary)

            Text("Sign in with Apple and other providers will connect here.")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, Theme.Spacing.md)

            Spacer(minLength: Theme.Spacing.md)

            VStack(spacing: Theme.Spacing.sm) {
                BaselineButton(title: "Preview onboarding") {
                    auth.startOnboarding()
                }
                .accessibilityIdentifier("login.previewOnboarding")

                Button("Preview signed-in home") {
                    auth.completeOnboarding(preferredName: nil)
                }
                .font(Theme.Typography.subheadline())
                .foregroundStyle(Theme.Colors.textMuted)
                .buttonStyle(.plain)
            }
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.bottom, Theme.Spacing.lg)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}
