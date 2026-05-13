import SwiftUI

struct OnboardingSetupView: View {
    var body: some View {
        Text("Setup")
            .font(Theme.Typography.title2())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
