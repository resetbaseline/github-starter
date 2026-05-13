import SwiftUI

struct CoachMessageView: View {
    @EnvironmentObject private var viewModel: CoachViewModel

    var body: some View {
        Text("Coach")
            .font(Theme.Typography.body())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
