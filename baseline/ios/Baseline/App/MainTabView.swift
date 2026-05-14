import SwiftUI

/// Authenticated shell: primary navigation is the tab bar (Home, Check-in, Coach, Timers, Profile).
struct MainTabView: View {
    @State private var selection: AppTab = .home

    var body: some View {
        TabView(selection: $selection) {
            HomeView()
                .tabItem { Label(AppTab.home.title, systemImage: AppTab.home.systemImage) }
                .tag(AppTab.home)

            CheckInFlow()
                .tabItem { Label(AppTab.checkIn.title, systemImage: AppTab.checkIn.systemImage) }
                .tag(AppTab.checkIn)

            CoachView()
                .tabItem { Label(AppTab.coach.title, systemImage: AppTab.coach.systemImage) }
                .tag(AppTab.coach)

            TimersView()
                .tabItem { Label(AppTab.timers.title, systemImage: AppTab.timers.systemImage) }
                .tag(AppTab.timers)

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
    case checkIn
    case coach
    case timers
    case profile

    var title: String {
        switch self {
        case .home: "Home"
        case .checkIn: "Check-in"
        case .coach: "Coach"
        case .timers: "Timers"
        case .profile: "Profile"
        }
    }

    var systemImage: String {
        switch self {
        case .home: "house.fill"
        case .checkIn: "checkmark.circle.fill"
        case .coach: "bubble.left.and.bubble.right.fill"
        case .timers: "timer"
        case .profile: "person.fill"
        }
    }
}
