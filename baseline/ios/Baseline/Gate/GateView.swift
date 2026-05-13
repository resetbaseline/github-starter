import SwiftUI

struct GateView: View {
    @StateObject private var viewModel = GateViewModel()

    var body: some View {
        NavigationStack {
            Text("Gate")
                .font(Theme.Typography.body())
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Colors.background)
                .navigationTitle("Gate")
        }
        .environmentObject(viewModel)
    }
}
