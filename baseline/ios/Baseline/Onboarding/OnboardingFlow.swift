import SwiftUI

struct OnboardingFlow: View {
    var body: some View {
        TabView {
            OnboardingScreen1()
            OnboardingScreen2()
            OnboardingScreen3()
            OnboardingScreen4()
            OnboardingSetupView()
        }
        .tabViewStyle(.page)
        .background(Theme.Colors.background)
    }
}
