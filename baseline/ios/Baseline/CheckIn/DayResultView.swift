import SwiftUI

struct DayResultView: View {
    var body: some View {
        Text("Day result")
            .font(Theme.Typography.title3())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
