import SwiftUI

@main
struct BaselineApp: App {
    @StateObject private var authManager = AuthManager()

    init() {
        AppAppearance.configure()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authManager)
                .preferredColorScheme(.dark)
        }
    }
}
