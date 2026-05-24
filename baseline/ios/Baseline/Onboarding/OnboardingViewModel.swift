import Combine
import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let totalSteps = 5

    /// 0…2 intro pages, 3 long-term goals, 4 setup.
    @Published var step: Int = 0

    /// Draft long-term goals (saved to `AuthManager` on final onboarding completion).
    @Published var longTermGoalDrafts: [LongTermGoalDraft] = []

    var longTermGoals: [(text: String, category: String)] {
        longTermGoalDrafts.map { (text: $0.text, category: $0.category) }
    }

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

    func saveLongTermGoals(_ goals: [LongTermGoalDraft], auth: AuthManager? = nil) {
        longTermGoalDrafts = goals
        guard !goals.isEmpty else { return }

        Task {
            var updated = goals
            for index in updated.indices {
                let symbol = await fetchIconSymbol(for: updated[index].text)
                updated[index].symbolName = symbol
            }
            longTermGoalDrafts = updated
            auth?.persistLongTermGoals(updated)
        }
    }

    private func fetchIconSymbol(for goalText: String) async -> String {
        let fallback = "star.fill"
        let validSymbols = [
            "briefcase.fill", "figure.run", "music.note", "book.fill",
            "dollarsign.circle.fill", "heart.fill", "brain.head.profile", "pencil.and.outline",
            "fork.knife", "moon.fill", "figure.strengthtraining.traditional", "paintbrush.fill",
            "globe", "camera.fill", "house.fill", "graduationcap.fill", "trophy.fill", "star.fill",
        ]
        let prompt = """
        Pick the single most appropriate SF Symbol name from this list for the goal: "\(goalText)"
        List: \(validSymbols.joined(separator: ", "))
        Reply with only the symbol name, nothing else.
        """
        guard let url = URL(string: "https://api.anthropic.com/v1/messages") else { return fallback }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        let body: [String: Any] = [
            "model": "claude-haiku-4-5-20251001",
            "max_tokens": 20,
            "messages": [["role": "user", "content": prompt]],
        ]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        guard let (data, _) = try? await URLSession.shared.data(for: request),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = (json["content"] as? [[String: Any]])?.first?["text"] as? String
        else {
            return fallback
        }
        let symbol = content.trimmingCharacters(in: .whitespacesAndNewlines)
        return validSymbols.contains(symbol) ? symbol : fallback
    }

    /// Label for a fixed page index (0-based), for views outside the view model instance.
    static func stepLabel(forStaticPage pageIndex: Int) -> String {
        "\(pageIndex + 1) of \(Self.totalSteps)"
    }
}
