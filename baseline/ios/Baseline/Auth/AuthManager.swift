import Combine
import SwiftUI

@MainActor
final class AuthManager: ObservableObject {
    enum State: Equatable {
        case loading
        case unauthenticated
        case onboarding
        case authenticated
    }

    @Published var state: State = .loading

    /// Display name captured during onboarding; wire to Supabase `users` when auth exists.
    @Published private(set) var onboardingPreferredName: String?

    init() {
        // Wire Supabase auth session in a later task; start unauthenticated for a compilable shell.
        state = .unauthenticated
    }

    /// Call after sign-up succeeds or from a dev entry point to show onboarding.
    func startOnboarding() {
        state = .onboarding
    }

    /// Finishes onboarding and enters the main app shell.
    func completeOnboarding(preferredName: String?) {
        onboardingPreferredName = preferredName
        state = .authenticated
    }
}
