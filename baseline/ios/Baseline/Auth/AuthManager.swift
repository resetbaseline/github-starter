import Combine
import Foundation
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

    @AppStorage("baseline.longTermGoals") var longTermGoalsJSON: String = "[]"

    private enum StorageKey {
        /// Same keys as `@AppStorage("baseline.wakeTime")` / `@AppStorage("baseline.checkInTime")` (TimeInterval since 1970).
        static let wakeTime = "baseline.wakeTime"
        static let checkInTime = "baseline.checkInTime"
    }

    private struct StoredLongTermGoal: Codable {
        let text: String
        let category: String
    }

    /// Long-term goals from onboarding (JSON in `UserDefaults` / `AppStorage`).
    var longTermGoals: [(text: String, category: String)] {
        guard let data = longTermGoalsJSON.data(using: .utf8),
              let rows = try? JSONDecoder().decode([StoredLongTermGoal].self, from: data)
        else {
            return []
        }
        return rows.map { (text: $0.text, category: $0.category) }
    }

    init() {
        // Wire Supabase auth session in a later task; start unauthenticated for a compilable shell.
        state = .unauthenticated
    }

    /// Call after sign-up succeeds or from a dev entry point to show onboarding.
    func startOnboarding() {
        state = .onboarding
    }

    /// Finishes onboarding and enters the main app shell.
    func completeOnboarding(
        preferredName: String?,
        wakeTime: Date = Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date(),
        checkInTime: Date =
            Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date(),
        longTermGoals: [(text: String, category: String)] = [],
    ) {
        onboardingPreferredName = preferredName
        UserDefaults.standard.set(wakeTime.timeIntervalSince1970, forKey: StorageKey.wakeTime)
        UserDefaults.standard.set(checkInTime.timeIntervalSince1970, forKey: StorageKey.checkInTime)

        let rows = longTermGoals.map { StoredLongTermGoal(text: $0.text, category: $0.category) }
        if let data = try? JSONEncoder().encode(rows), let json = String(data: data, encoding: .utf8) {
            longTermGoalsJSON = json
        } else {
            longTermGoalsJSON = "[]"
        }

        state = .authenticated
    }
}
