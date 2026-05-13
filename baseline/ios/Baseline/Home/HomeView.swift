import SwiftUI

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    StreakCardView()
                    GoalsListView()
                }
                .padding(Theme.Spacing.sm)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Today")
        }
        .environmentObject(viewModel)
    }
}
