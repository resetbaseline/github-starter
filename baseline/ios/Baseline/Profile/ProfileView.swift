import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var viewModel = ProfileViewModel()

    var body: some View {
        NavigationStack {
            List {
                if let name = auth.onboardingPreferredName, !name.isEmpty {
                    VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                        Text("Name")
                            .font(Theme.Typography.caption1())
                            .foregroundStyle(Theme.Colors.textMuted)
                        Text(name)
                            .font(Theme.Typography.body())
                            .foregroundStyle(Theme.Colors.textPrimary)
                    }
                    .listRowBackground(Theme.Colors.surface)
                }
                Text("Profile")
                    .listRowBackground(Theme.Colors.surface)
            }
            .scrollContentBackground(.hidden)
            .background(Theme.Colors.background)
            .navigationTitle("Profile")
        }
        .environmentObject(viewModel)
    }
}
