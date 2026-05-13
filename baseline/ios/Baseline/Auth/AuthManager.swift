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

    init() {
        // Wire Supabase auth session in a later task; start unauthenticated for a compilable shell.
        state = .unauthenticated
    }
}
