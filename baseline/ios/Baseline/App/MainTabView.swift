import SwiftUI

/// Authenticated shell: primary navigation is the tab bar (Home, Focus, Coach, Profile).
struct MainTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
                .tag(AppTab.home)

            TimersView()
                .tabItem { Label(AppTab.focus.title, systemImage: AppTab.focus.systemImage) }
                .tag(AppTab.focus)

            CoachView()
                .tabItem { Label(AppTab.coach.title, systemImage: AppTab.coach.systemImage) }
                .tag(AppTab.coach)

            ProfileView()
                .tabItem { Label(AppTab.profile.title, systemImage: AppTab.profile.systemImage) }
                .tag(AppTab.profile)
        }
        .tint(Theme.Colors.accent)
        .toolbarBackground(Theme.TabBar.background, for: .tabBar)
        .toolbarBackground(.visible, for: .tabBar)
        .toolbarColorScheme(.dark, for: .tabBar)
        .background(Theme.Colors.background)
    }
}

private enum AppTab: Hashable {
    case home
    case focus
    case coach
    case profile

    var title: String {
        switch self {
        case .home: "Home"
        case .focus: "Focus"
        case .coach: "Coach"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .focus: "bolt.fill"
        case .coach: "bubble.left.and.bubble.right.fill"
        case .profile: "person.fill"
        }
    }
}
