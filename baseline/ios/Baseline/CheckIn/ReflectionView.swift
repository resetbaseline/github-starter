import SwiftUI

struct ReflectionView: View {
    var body: some View {
        Text("Reflection")
            .font(Theme.Typography.body())
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
    }
}
