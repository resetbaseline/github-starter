import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var onboarding = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $onboarding.step) {
                OnboardingScreen1()
                    .tag(0)
                OnboardingScreen2()
                    .tag(1)
                OnboardingScreen3()
                    .tag(2)
                OnboardingScreen4()
                    .tag(3)
                OnboardingSetupView()
                    .tag(4)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Theme.Animation.screenTransition, value: onboarding.step)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            bottomChrome
        }
        .environmentObject(onboarding)
        .background(Theme.Colors.background.ignoresSafeArea())
    }

    private var bottomChrome: some View {
        VStack(spacing: Theme.Spacing.md) {
            pageDots

            HStack(spacing: Theme.Spacing.sm) {
                if !onboarding.isFirstStep {
                    Button("Back") {
                        onboarding.goBack()
                    }
                    .font(Theme.Typography.headline())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .buttonStyle(.plain)
                }

                if !onboarding.isSetupStep {
                    BaselineButton(title: "Continue") {
                        onboarding.goNext()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.horizontal, Theme.Spacing.md)
        .padding(.top, Theme.Spacing.sm)
        .padding(.bottom, Theme.Spacing.md)
        .background(
            Theme.Colors.surface
                .shadow(color: .black.opacity(0.35), radius: 12, y: -4)
        )
    }

    private var pageDots: some View {
        HStack(spacing: Theme.Spacing.xs) {
            ForEach(0 ..< OnboardingViewModel.totalSteps, id: \.self) { index in
                Capsule()
                    .fill(index == onboarding.step ? Theme.Colors.accent : Theme.Colors.border)
                    .frame(width: index == onboarding.step ? 20 : 6, height: 6)
                    .animation(Theme.Animation.interactive, value: onboarding.step)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding step \(onboarding.step + 1) of \(OnboardingViewModel.totalSteps)")
    }
}
