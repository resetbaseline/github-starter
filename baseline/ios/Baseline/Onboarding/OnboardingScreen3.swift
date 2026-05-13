import SwiftUI

struct OnboardingScreen3: View {
    var body: some View {
        Text("Coach")
            .font(Theme.Typography.title2())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
