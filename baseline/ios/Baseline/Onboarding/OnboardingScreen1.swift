import SwiftUI

struct OnboardingScreen1: View {
    var body: some View {
        Text("Welcome")
            .font(Theme.Typography.title2())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
