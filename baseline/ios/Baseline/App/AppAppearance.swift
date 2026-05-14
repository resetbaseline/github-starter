import SwiftUI
import UIKit

/// Global UIKit chrome for the app shell (navigation + tab bar). Call once at launch.
enum AppAppearance {
    static func configure() {
        configureNavigationBar()
        configureTabBar()
    }

    private static func configureNavigationBar() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.TabBar.backgroundUIColor
        appearance.shadowColor = .clear
        let titleColor = Theme.TabBar.primaryLabelUIColor
        appearance.titleTextAttributes = [.foregroundColor: titleColor]
        appearance.largeTitleTextAttributes = [.foregroundColor: titleColor]

        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
        UINavigationBar.appearance().compactAppearance = appearance
        UINavigationBar.appearance().tintColor = Theme.TabBar.accentUIColor
    }

    private static func configureTabBar() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = Theme.TabBar.backgroundUIColor
        appearance.shadowColor = .clear
        appearance.shadowImage = UIImage()

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isTranslucent = false
        UITabBar.appearance().tintColor = Theme.TabBar.accentUIColor
        UITabBar.appearance().unselectedItemTintColor = Theme.TabBar.unselectedItemUIColor
    }
}
