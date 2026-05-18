import SwiftUI

struct OnboardingScreen1: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var showSecondLine = false

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                Spacer(minLength: 0)

                VStack(spacing: Theme.Spacing.md) {
                    Text("People are not lazy.")
                        .font(.system(size: 34, weight: .thin, design: .serif))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .multilineTextAlignment(.center)

                    Text("They are overstimulated.")
                        .font(.system(size: 34, weight: .thin, design: .serif))
                        .foregroundStyle(Theme.Colors.textSecondary)
                        .multilineTextAlignment(.center)
                        .opacity(showSecondLine ? 1 : 0)
                }
                .padding(.horizontal, Theme.Spacing.md)

                Spacer(minLength: 0)

                Text("Tap to continue")
                    .font(Theme.Typography.caption1())
                    .foregroundStyle(Theme.Colors.textMuted)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, Theme.Spacing.md)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onboarding.goNext()
        }
        .onAppear {
            showSecondLine = false
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                withAnimation(.easeIn(duration: 0.6)) {
                    showSecondLine = true
                }
            }
        }
    }
}
