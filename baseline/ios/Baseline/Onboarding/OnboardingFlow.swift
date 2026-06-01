import SwiftUI

struct OnboardingFlow: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var onboarding = OnboardingViewModel()

    var body: some View {
        VStack(spacing: 0) {
            TabView(selection: $onboarding.step) {
                OnboardingScreen1(onNext: { onboarding.goNext() })
                    .tag(0)
                OnboardingScreen2(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(1)
                OnboardingScreen3(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(2)
                OnboardingScreen4(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(3)
                OnboardingScreen5(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(4)
                OnboardingScreen6(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(5)
                OnboardingScreen7(
                    onNext: { onboarding.goNext() },
                    viewModel: onboarding,
                )
                    .tag(6)
                OnboardingScreen8(onNext: { onboarding.goNext() })
                    .tag(7)
                OnboardingScreen9(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(8)
                OnboardingScreen10(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(9)
                OnboardingScreen11(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(10)
                OnboardingScreen12(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(11)
                OnboardingScreen13(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(12)
                OnboardingScreen14(
                    onNext: { onboarding.goNext() },
                    onBack: { onboarding.goBack() },
                )
                    .tag(13)
                OnboardingSetupView()
                    .tag(14)
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .animation(Theme.Animation.screenTransition, value: onboarding.step)
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            if onboarding.step != 0 && onboarding.step != 1 && onboarding.step != 2 && onboarding.step != 3 && onboarding.step != 4 && onboarding.step != 5 && onboarding.step != 6 && onboarding.step != 7 && onboarding.step != 8 && onboarding.step != 9 && onboarding.step != 10 && onboarding.step != 11 && onboarding.step != 12 && onboarding.step != 13 {
                bottomChrome
            }
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
