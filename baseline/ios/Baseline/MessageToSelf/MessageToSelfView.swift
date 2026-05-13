import SwiftUI

struct MessageToSelfView: View {
    @StateObject private var viewModel = MessageToSelfViewModel()

    var body: some View {
        NavigationStack {
            Text("Message to self")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.background)
                .navigationTitle("Future self")
        }
        .environmentObject(viewModel)
    }
}
