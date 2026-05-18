import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let totalSteps = 5

    /// 0…2 intro pages, 3 long-term goals, 4 setup.
    @Published var step: Int = 0

    /// Draft long-term goals (saved to `AuthManager` on final onboarding completion).
    @Published var longTermGoals: [(text: String, category: String)] = []

    var isFirstStep: Bool { step == 0 }
    var isSetupStep: Bool { step == Self.totalSteps - 1 }
    /// Long-term goals screen manages its own primary actions.
    var isLongTermGoalsStep: Bool { step == 3 }

    func stepLabel(forPage index: Int) -> String {
        "\(index + 1) of \(Self.totalSteps)"
    }

    func goNext() {
        step = min(step + 1, Self.totalSteps - 1)
        Theme.Haptics.lightImpact()
    }

    func goBack() {
        step = max(step - 1, 0)
        Theme.Haptics.lightImpact()
    }

    func saveLongTermGoals(_ goals: [(text: String, category: String)]) {
        longTermGoals = goals
    }

    /// Label for a fixed page index (0-based), for views outside the view model instance.
    static func stepLabel(forStaticPage pageIndex: Int) -> String {
        "\(pageIndex + 1) of \(Self.totalSteps)"
    }
}
