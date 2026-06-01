import Combine
import FamilyControls
import Foundation
import SwiftUI

@MainActor
final class OnboardingViewModel: ObservableObject {
    static let totalSteps = 15

    /// 0…13 intro pages, 14 setup.
    @Published var step: Int = 0

    /// Draft long-term goals (saved to `AuthManager` on final onboarding completion).
    @Published var longTermGoalDrafts: [LongTermGoalDraft] = []
    @Published var preferredName: String = ""
    @Published var distractions: [String] = []
    @Published var vulnerableTimeWindow: String?
    @Published var behavioralPatterns: [String] = []
    @Published var userAge: Int = 22
    @Published var dailyPhoneHours: Double = 4.0
    @Published var yearsOnPhone: Double = 0.0
    @Published var hasSeenReframe: Bool = false
    @Published var selectedLifeAreas: [String] = []
    @Published var lifeAreaDescription: String = ""
    @Published var goalDetails: [String: String] = [:]
    @Published var goalClassifications: [String: GoalClassification] = [:]
    @Published var goalDates: [String: Date?] = [:]
    @Published var anchors: [OnboardingAnchor] = []
    @Published var gateSettings: GateSettings?

    var longTermGoals: [(text: String, category: String)] {
        longTermGoalDrafts.map { (text: $0.text, category: $0.category) }
    }

    var isFirstStep: Bool { step == 0 }
    var isSetupStep: Bool { step == Self.totalSteps - 1 }
    /// Legacy `LongTermGoalsView` when re-inserted in the flow.
    var isLongTermGoalsStep: Bool { false }

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

    func setPreferredName(_ name: String) {
        preferredName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    func setDistractions(_ distractions: [String]) {
        self.distractions = distractions
    }

    func setVulnerableTimeWindow(_ window: String?) {
        vulnerableTimeWindow = window
    }

    func setBehavioralPatterns(_ patterns: [String]) {
        behavioralPatterns = patterns
    }

    func setTimeEstimate(age: Int, dailyHours: Double, yearsOnPhone: Double) {
        userAge = age
        dailyPhoneHours = dailyHours
        self.yearsOnPhone = yearsOnPhone
    }

    func markReframeSeen() {
        hasSeenReframe = true
    }

    func setLifeAreas(areas: [String], description: String) {
        selectedLifeAreas = areas
        lifeAreaDescription = description
    }

    func setGoalDetails(_ details: [String: String]) {
        goalDetails = details.filter {
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }
    }

    func setGoalClassifications(_ classifications: [String: GoalClassification]) {
        goalClassifications = classifications
    }

    func setDefaultClassifications(for areas: [String]) {
        var classifications = goalClassifications
        for area in areas {
            classifications[area] = GoalClassification(type: "outcome", extractedDate: nil)
        }
        goalClassifications = classifications
    }

    func setGoalDate(_ date: Date?, for area: String) {
        var dates = goalDates
        dates[area] = date
        goalDates = dates
    }

    func setAnchors(_ anchors: [OnboardingAnchor]) {
        self.anchors = anchors
    }

    func setGateSettings(
        enabled: Bool,
        activationMode: String,
        activitySelection: FamilyActivitySelection,
    ) {
        gateSettings = GateSettings(
            enabled: enabled,
            activationMode: activationMode,
            activitySelection: activitySelection,
        )
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
