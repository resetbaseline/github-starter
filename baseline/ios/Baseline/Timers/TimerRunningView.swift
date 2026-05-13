import SwiftUI

struct TimerRunningView: View {
    @EnvironmentObject private var viewModel: TimersViewModel

    var body: some View {
        Text("Timer")
            .font(Theme.Typography.title3())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
