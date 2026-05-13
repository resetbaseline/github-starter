import SwiftUI

struct RootView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        Group {
            switch auth.state {
            case .loading:
                ProgressView()
                    .tint(Theme.Colors.accent)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Theme.Colors.background)
            case .unauthenticated:
                LoginView()
            case .onboarding:
                OnboardingFlow()
            case .authenticated:
                HomeView()
            }
        }
        .animation(Theme.Animation.screenTransition, value: auth.state)
    }
}
