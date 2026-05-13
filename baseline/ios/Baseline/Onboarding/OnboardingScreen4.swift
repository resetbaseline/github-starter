import SwiftUI

struct OnboardingScreen4: View {
    var body: some View {
        Text("Rhythm")
            .font(Theme.Typography.title2())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
