import Combine
import Foundation
import SwiftUI

/// Goal row during check-in (matches `goals` + `goal_outcomes` shape for a future `process-checkin` call).
struct CheckInGoalRow: Identifiable, Equatable {
    let id: UUID
    let title: String
    let isNonNegotiable: Bool
    var completed: Bool
}

struct TomorrowGoalDraft: Identifiable, Equatable {
    let id: UUID
    var text: String
    var category: String
    var isAccepted: Bool
    var isSuggested: Bool
}

@MainActor
final class CheckInViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case goalReview = 0
        case reflection = 1
        case planTomorrow = 2
        case dayResult = 3
    }

    @Published var step: Step = .goalReview

    @Published var goals: [CheckInGoalRow] = []

    /// Maps reflection question id → selected chip labels.
    @Published var selectedChips: [UUID: Set<String>] = [:]

    @Published var openEndedText: String = ""

    /// Client-side coach blurb (kept in sync with `aiSuggestionText`).
    @Published var aiSuggestion: String = ""

    @Published var selectedQuestions: [ReflectionQuestion] = []

    /// Mock gate opens today (for question routing).
    @Published var gateCount: Int = 2

    /// Mock focus minutes for the day (from `days.focus_minutes_total` when wired).
    @Published var focusMinutesTotal: Int = 32

    @Published var tomorrowIntention: String = ""

    @Published var tomorrowNonNegotiables: [TomorrowGoalDraft] = []
    @Published var tomorrowOtherGoals: [TomorrowGoalDraft] = []

    /// After `finalizeResult()`: `strong`, `solid`, or `light` (same vocabulary as Supabase `day_status`).
    @Published private(set) var computedDayStatus: String = ""

    @Published private(set) var streakBefore: Int = 7
    @Published private(set) var streakAfter: Int = 7

    /// When the day is `light`, user can opt into a streak freeze (UI only until API exists).
    @Published var useStreakFreeze: Bool = false

    func setStreakFreeze(_ value: Bool) {
        useStreakFreeze = value
        refreshStreakAfterFreezeChange()
    }

    private static let stableGoalIds: [UUID] = (1 ... 5).map { i in
        UUID(uuidString: String(format: "10000000-0000-4000-8000-%012x", i))!
    }

    init() {
        loadInitialDraft()
    }

    /// Suggested rows the coach pre-filled (carryovers + long-term daily actions).
    var coachSuggestedGoals: [TomorrowGoalDraft] {
        tomorrowNonNegotiables.filter(\.isSuggested) + tomorrowOtherGoals.filter(\.isSuggested)
    }

    var suggestedIntentionText: String {
        if let first = tomorrowNonNegotiables.first(where: { $0.isAccepted }) {
            return "Start with \(first.text) — set a focus block for the morning."
        }
        return "Decide on one non-negotiable before the day starts."
    }

    /// Counts reflection questions with at least one chip selected.
    var reflectionAnswerCount: Int {
        selectedQuestions.filter { !(selectedChips[$0.id, default: []].isEmpty) }.count
    }

    var aiSuggestionText: String {
        aiSuggestion
    }

    func toggleChip(questionId: UUID, chip: String) {
        var next = selectedChips
        var set = next[questionId, default: []]
        if set.contains(chip) {
            set.remove(chip)
        } else {
            set.insert(chip)
        }
        if set.isEmpty {
            next.removeValue(forKey: questionId)
        } else {
            next[questionId] = set
        }
        selectedChips = next
        aiSuggestion = Self.buildCoachObservation(selectedChips: next)
    }

    func toggleGoal(id: UUID) {
        guard let i = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[i].completed.toggle()
        Theme.Haptics.lightImpact()
    }

    func goToReflection() {
        step = .reflection
        Theme.Haptics.lightImpact()
    }

    func goToPlanTomorrow(auth: AuthManager) {
        populateTomorrowDrafts(from: auth)
        step = .planTomorrow
        Theme.Haptics.lightImpact()
    }

    func submitReflectionAndShowResult(auth: AuthManager) {
        goToPlanTomorrow(auth: auth)
    }

    func finalizePlanAndShowResult() {
        finalizeResult()
        step = .dayResult
        Theme.Haptics.lightImpact()
    }

    func acceptSuggestion(id: UUID) {
        if let i = tomorrowNonNegotiables.firstIndex(where: { $0.id == id }) {
            var row = tomorrowNonNegotiables[i]
            row.isAccepted.toggle()
            tomorrowNonNegotiables[i] = row
            return
        }
        if let i = tomorrowOtherGoals.firstIndex(where: { $0.id == id }) {
            var row = tomorrowOtherGoals[i]
            row.isAccepted.toggle()
            tomorrowOtherGoals[i] = row
        }
    }

    func addCustomTomorrowGoal(text: String, isNonNegotiable: Bool) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let draft = TomorrowGoalDraft(
            id: UUID(),
            text: trimmed,
            category: isNonNegotiable ? "Must-do" : "Custom",
            isAccepted: true,
            isSuggested: false,
        )
        if isNonNegotiable {
            tomorrowNonNegotiables.append(draft)
        } else {
            tomorrowOtherGoals.append(draft)
        }
    }

    func removeTomorrowGoal(id: UUID) {
        tomorrowNonNegotiables.removeAll { $0.id == id }
        tomorrowOtherGoals.removeAll { $0.id == id }
    }

    func goBack() {
        if step == .dayResult {
            computedDayStatus = ""
            streakAfter = streakBefore
            useStreakFreeze = false
        }
        if step.rawValue > 0 {
            step = Step(rawValue: step.rawValue - 1) ?? .goalReview
            Theme.Haptics.lightImpact()
        }
    }

    var canGoBack: Bool { step.rawValue > 0 }

    /// Re-run streak numbers when `light` + freeze toggle changes on the result screen.
    func refreshStreakAfterFreezeChange() {
        guard computedDayStatus == "light" else { return }
        applyLightStreakOutcome()
    }

    func completeCheckInAndReset() {
        streakBefore = streakAfter
        loadInitialDraft()
        step = .goalReview
        computedDayStatus = ""
        streakAfter = streakBefore
        useStreakFreeze = false
        Theme.Haptics.goalCompleted()
    }

    private func loadInitialDraft() {
        goals = [
            CheckInGoalRow(id: Self.stableGoalIds[0], title: "Morning movement", isNonNegotiable: true, completed: false),
            CheckInGoalRow(id: Self.stableGoalIds[1], title: "Deep work — project brief", isNonNegotiable: true, completed: false),
            CheckInGoalRow(id: Self.stableGoalIds[2], title: "Reply to two priority emails", isNonNegotiable: false, completed: false),
            CheckInGoalRow(id: Self.stableGoalIds[3], title: "Walk at lunch", isNonNegotiable: false, completed: false),
            CheckInGoalRow(id: Self.stableGoalIds[4], title: "Plan tomorrow in Baseline", isNonNegotiable: false, completed: false),
        ]

        selectedChips = [:]
        openEndedText = ""
        aiSuggestion = Self.buildCoachObservation(selectedChips: [:])

        let mockGoalsCompleted = 2
        let mockGoalsTotal = 5
        selectedQuestions = ReflectionQuestionBank.selectQuestionsForDay(
            gateCount: gateCount,
            focusMinutes: focusMinutesTotal,
            goalsCompleted: mockGoalsCompleted,
            goalsTotal: mockGoalsTotal,
            dayOfWeek: 3,
        )
        tomorrowIntention = ""
        tomorrowNonNegotiables = []
        tomorrowOtherGoals = []
    }

    private func populateTomorrowDrafts(from auth: AuthManager) {
        let incomplete = goals.filter { !$0.completed }
        tomorrowNonNegotiables = incomplete.prefix(3).map { goal in
            TomorrowGoalDraft(
                id: UUID(),
                text: goal.title,
                category: goal.isNonNegotiable ? "Non-negotiable" : "Today",
                isAccepted: true,
                isSuggested: true,
            )
        }

        tomorrowOtherGoals = auth.longTermGoals.map { lt in
            TomorrowGoalDraft(
                id: UUID(),
                text: Self.dailyActionLine(longTermText: lt.text, category: lt.category),
                category: lt.category,
                isAccepted: false,
                isSuggested: true,
            )
        }
    }

    private static func dailyActionLine(longTermText: String, category: String) -> String {
        switch category {
        case "Work":
            return "30 min on: \(longTermText)"
        case "Health":
            return "Complete: \(longTermText)"
        case "Learning":
            return "Study session: \(longTermText)"
        case "Creative":
            return "Create: \(longTermText)"
        case "Finance":
            return "Review: \(longTermText)"
        case "Personal":
            return longTermText
        default:
            return longTermText
        }
    }

    /// Mirrors `process-checkin` `classifyDayResult` (without `rest` / `skipped` paths used here).
    private func classifyDayStatus() -> String {
        if goals.isEmpty && focusMinutesTotal == 0 { return "skipped" }

        let nnGoals = goals.filter(\.isNonNegotiable)
        let allNnComplete = nnGoals.isEmpty || nnGoals.allSatisfy(\.completed)
        let anyNnCompleted = nnGoals.contains(where: \.completed)
        let anyGoalCompleted = goals.contains(where: \.completed)
        let rc = reflectionAnswerCount

        if allNnComplete && rc >= 1 { return "strong" }
        if anyNnCompleted || anyGoalCompleted { return "solid" }
        return "light"
    }

    private func finalizeResult() {
        computedDayStatus = classifyDayStatus()
        switch computedDayStatus {
        case "strong", "solid":
            useStreakFreeze = false
            streakAfter = streakBefore + 1
        case "light":
            applyLightStreakOutcome()
        case "skipped":
            streakAfter = streakBefore
        default:
            streakAfter = streakBefore
        }
    }

    private func applyLightStreakOutcome() {
        streakAfter = useStreakFreeze ? streakBefore : 0
    }

    private static func buildCoachObservation(selectedChips: [UUID: Set<String>]) -> String {
        let flat = Set(selectedChips.values.flatMap { $0 })
        if flat.contains("Low energy") {
            return "Low energy day noted — afternoon looks like the weak point. Want to front-load tomorrow?"
        }
        if flat.contains("A little") {
            return "Some scrolling, manageable. Worth watching if it becomes a pattern."
        }
        if flat.contains("It took over") {
            return "Phone took over today. The gate data will have more context."
        }
        if flat.contains("Crashed midday") {
            return "Midday crash logged — consider a lighter morning or a real lunch break tomorrow."
        }
        if flat.contains("Way too many") {
            return "List overload today. Tomorrow might feel better with one fewer must-do."
        }
        return "Selections noted. Coach will use these in tonight's note."
    }
}

extension CheckInViewModel {
    var goalsCompletedCount: Int {
        goals.filter(\.completed).count
    }

    var nonNegotiableCompletedCount: Int {
        goals.filter { $0.isNonNegotiable && $0.completed }.count
    }

    var nonNegotiableTotalCount: Int {
        goals.filter(\.isNonNegotiable).count
    }

    var dayStatusHeadline: String {
        switch computedDayStatus {
        case "strong": return "Strong day"
        case "solid": return "Solid day"
        case "light": return "Light day"
        case "skipped": return "Day logged"
        default: return "Day summary"
        }
    }

    var dayStatusBody: String {
        switch computedDayStatus {
        case "strong":
            return "Every non-negotiable is done and you left at least one reflection—your baseline held."
        case "solid":
            return "You moved something forward today—either a must-do or another goal—and that counts in the log."
        case "light":
            return "Check-in is in, but nothing was marked complete. The streak can reset unless you use a freeze you already have."
        case "skipped":
            return "No goals and no focus time on record—this day is treated as skipped for streak math."
        default:
            return ""
        }
    }

    var streakChangeDescription: String {
        if streakAfter == streakBefore + 1 {
            return "Streak moves forward after tonight’s check-in."
        }
        if computedDayStatus == "light" && useStreakFreeze {
            return "Streak holds steady—freeze applied for this light day."
        }
        if computedDayStatus == "light" && !useStreakFreeze {
            return "Streak resets to zero from this light day (mock—server will set the new start date)."
        }
        return "Streak unchanged for this outcome."
    }

    /// Stub coach note for the result screen.
    var coachNotePreview: String {
        let chips = selectedChips.values.flatMap { $0 }.sorted()
        let chipSnippet = chips.first.map { " You flagged “\($0)” in reflection." } ?? ""
        switch computedDayStatus {
        case "strong":
            return "Strong finish—baseline held across non-negotiables and reflection.\(chipSnippet) I’ll fold that into tonight’s note."
        case "solid":
            return "Solid day: progress without a perfect sweep is still signal.\(chipSnippet) We’ll build from here."
        case "light":
            return "Light day logged—no shame, just data.\(chipSnippet) We can tighten the plan when you’re ready."
        case "skipped":
            return "Day marked skipped for streak math.\(chipSnippet) Fresh start whenever you want it."
        default:
            return "Thanks for checking in.\(chipSnippet)"
        }
    }
}
