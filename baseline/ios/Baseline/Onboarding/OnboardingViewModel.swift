import Combine
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let totalSteps = 5

    /// 0…3 intro pages, 4 setup.
    @Published var step: Int = 0

    var isFirstStep: Bool { step == 0 }
    var isSetupStep: Bool { step == Self.totalSteps - 1 }

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

    /// Label for a fixed page index (0-based), for views outside the view model instance.
    static func stepLabel(forStaticPage pageIndex: Int) -> String {
        "\(pageIndex + 1) of \(Self.totalSteps)"
    }
}
