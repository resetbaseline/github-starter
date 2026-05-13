import SwiftUI

struct SignUpView: View {
    var body: some View {
        Text("Sign up")
            .font(Theme.Typography.body())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
