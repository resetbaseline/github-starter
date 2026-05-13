import SwiftUI

struct GoalReviewView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel

    var body: some View {
        Text("Goal review")
            .font(Theme.Typography.body())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
