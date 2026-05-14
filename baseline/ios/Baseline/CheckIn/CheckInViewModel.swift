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

/// Draft reflection row (maps to `reflection_answers`: question_text, answer, category).
struct ReflectionDraft: Identifiable, Equatable {
    let id: UUID
    let questionText: String
    let category: String
    var answer: String
}

@MainActor
final class CheckInViewModel: ObservableObject {
    enum Step: Int, CaseIterable {
        case goalReview = 0
        case reflection = 1
        case dayResult = 2
    }

    @Published var step: Step = .goalReview

    @Published var goals: [CheckInGoalRow] = []
    @Published var reflectionDrafts: [ReflectionDraft] = []

    /// Mock focus minutes for the day (from `days.focus_minutes_total` when wired).
    @Published var focusMinutesTotal: Int = 32

    @Published var tomorrowIntention: String = ""

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

    var reflectionAnswerCount: Int {
        reflectionDrafts.filter { !$0.answer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    func toggleGoal(id: UUID) {
        guard let i = goals.firstIndex(where: { $0.id == id }) else { return }
        goals[i].completed.toggle()
        Theme.Haptics.lightImpact()
    }

    func updateReflectionAnswer(id: UUID, text: String) {
        guard let i = reflectionDrafts.firstIndex(where: { $0.id == id }) else { return }
        reflectionDrafts[i].answer = text
    }

    func answer(for id: UUID) -> String {
        reflectionDrafts.first(where: { $0.id == id })?.answer ?? ""
    }

    func goToReflection() {
        step = .reflection
        Theme.Haptics.lightImpact()
    }

    func submitReflectionAndShowResult() {
        finalizeResult()
        step = .dayResult
        Theme.Haptics.lightImpact()
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

        reflectionDrafts = [
            ReflectionDraft(
                id: UUID(uuidString: "20000000-0000-4000-8000-000000000001")!,
                questionText: "What mattered most in how you used your time today?",
                category: "universal",
                answer: "",
            ),
            ReflectionDraft(
                id: UUID(uuidString: "20000000-0000-4000-8000-000000000002")!,
                questionText: "Where did friction show up—and was it useful?",
                category: "universal",
                answer: "",
            ),
            ReflectionDraft(
                id: UUID(uuidString: "20000000-0000-4000-8000-000000000003")!,
                questionText: "What is one thing you want to carry into tomorrow unchanged?",
                category: "universal",
                answer: "",
            ),
        ]
        tomorrowIntention = ""
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
}

extension CheckInViewModel {
    /// Human-readable status for UI (no win/loss wording).
    var goalsCompletedCount: Int {
        goals.filter(\.completed).count
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
}
