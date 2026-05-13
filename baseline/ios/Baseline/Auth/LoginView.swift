import SwiftUI

struct LoginView: View {
    var body: some View {
        VStack(spacing: Theme.Spacing.md) {
            Circle()
                .fill(Theme.Logo.color)
                .frame(width: Theme.Logo.diameter, height: Theme.Logo.diameter)
            Text("Baseline")
                .font(Theme.Typography.title1())
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Sign in")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.Colors.background)
    }
}
