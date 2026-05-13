import SwiftUI

struct OnboardingScreen2: View {
    var body: some View {
        Text("Gate")
            .font(Theme.Typography.title2())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
