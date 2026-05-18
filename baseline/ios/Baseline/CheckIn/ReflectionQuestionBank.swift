import Foundation

enum ReflectionQuestionCategory: String, CaseIterable, Equatable {
    case focusAttention
    case energyState
    case goalsExecution
    case environment
    case forwardIntention
}

struct ReflectionQuestion: Identifiable, Equatable {
    let id: UUID
    let text: String
    let category: ReflectionQuestionCategory
    let chips: [String]
}

enum ReflectionQuestionBank {
    private static let focusAttention: [ReflectionQuestion] = [
        ReflectionQuestion(
            id: UUID(uuidString: "A1000000-0000-4000-8000-000000000001")!,
            text: "Did you doomscroll today?",
            category: .focusAttention,
            chips: ["Not really", "A little", "Quite a bit", "It took over"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A1000000-0000-4000-8000-000000000002")!,
            text: "What stole your attention most?",
            category: .focusAttention,
            chips: ["Phone", "People", "My own thoughts", "Nothing major"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A1000000-0000-4000-8000-000000000003")!,
            text: "Did you protect your deep work window?",
            category: .focusAttention,
            chips: ["Yes, fully", "Partly", "Not really", "Had no window"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A1000000-0000-4000-8000-000000000004")!,
            text: "How was your phone use today?",
            category: .focusAttention,
            chips: ["Clean", "Average", "Heavy", "Out of control"],
        ),
    ]

    private static let energyState: [ReflectionQuestion] = [
        ReflectionQuestion(
            id: UUID(uuidString: "A2000000-0000-4000-8000-000000000001")!,
            text: "How was your energy today?",
            category: .energyState,
            chips: ["High", "Steady", "Low", "Crashed midday"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A2000000-0000-4000-8000-000000000002")!,
            text: "What drained you most?",
            category: .energyState,
            chips: ["Poor sleep", "Decision fatigue", "Social load", "Nothing specific"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A2000000-0000-4000-8000-000000000003")!,
            text: "Did you feel clear-headed?",
            category: .energyState,
            chips: ["Yes", "Mostly", "Patchy", "Not at all"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A2000000-0000-4000-8000-000000000004")!,
            text: "When were you sharpest?",
            category: .energyState,
            chips: ["Morning", "Midday", "Afternoon", "Evening"],
        ),
    ]

    private static let goalsExecution: [ReflectionQuestion] = [
        ReflectionQuestion(
            id: UUID(uuidString: "A3000000-0000-4000-8000-000000000001")!,
            text: "What got in the way?",
            category: .goalsExecution,
            chips: ["Low energy", "Avoidance", "Interruptions", "Goals too big"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A3000000-0000-4000-8000-000000000002")!,
            text: "Were your goals realistic today?",
            category: .goalsExecution,
            chips: ["Yes", "Mostly", "A bit ambitious", "Way too many"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A3000000-0000-4000-8000-000000000003")!,
            text: "What carried you forward?",
            category: .goalsExecution,
            chips: ["Momentum", "Accountability", "Routine", "Nothing — pushed through"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A3000000-0000-4000-8000-000000000004")!,
            text: "What would you drop if you could?",
            category: .goalsExecution,
            chips: ["Nothing", "One task", "Half my list", "All of it"],
        ),
    ]

    private static let environment: [ReflectionQuestion] = [
        ReflectionQuestion(
            id: UUID(uuidString: "A4000000-0000-4000-8000-000000000001")!,
            text: "What helped you most today?",
            category: .environment,
            chips: ["My setup", "Fewer distractions", "Good timing", "Other people"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A4000000-0000-4000-8000-000000000002")!,
            text: "What would you change about your setup?",
            category: .environment,
            chips: ["Nothing", "Less noise", "Better tools", "My schedule"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A4000000-0000-4000-8000-000000000003")!,
            text: "Did your schedule serve you?",
            category: .environment,
            chips: ["Perfectly", "Mostly", "Not really", "Had no schedule"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A4000000-0000-4000-8000-000000000004")!,
            text: "What was the biggest external friction?",
            category: .environment,
            chips: ["Interruptions", "Unexpected tasks", "Environment", "Nothing"],
        ),
    ]

    private static let forwardIntention: [ReflectionQuestion] = [
        ReflectionQuestion(
            id: UUID(uuidString: "A5000000-0000-4000-8000-000000000001")!,
            text: "What do you want to protect tomorrow?",
            category: .forwardIntention,
            chips: ["Morning focus", "Deep work block", "Energy", "Rest"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A5000000-0000-4000-8000-000000000002")!,
            text: "What are you carrying into tomorrow?",
            category: .forwardIntention,
            chips: ["Momentum", "A specific task", "A lesson", "A fresh start"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A5000000-0000-4000-8000-000000000003")!,
            text: "What would make tomorrow better?",
            category: .forwardIntention,
            chips: ["Earlier start", "Fewer goals", "Better focus block", "More rest"],
        ),
        ReflectionQuestion(
            id: UUID(uuidString: "A5000000-0000-4000-8000-000000000004")!,
            text: "What needs to change tomorrow?",
            category: .forwardIntention,
            chips: ["My schedule", "My goals", "My environment", "Nothing"],
        ),
    ]

    private static func pick(from questions: [ReflectionQuestion], seed: Int) -> ReflectionQuestion {
        let idx = seed % max(questions.count, 1)
        return questions[idx]
    }

    /// Returns exactly two questions: one reactive, one forward-looking (never the same instance).
    static func selectQuestionsForDay(
        gateCount: Int,
        focusMinutes: Int,
        goalsCompleted: Int,
        goalsTotal: Int,
        dayOfWeek: Int,
    ) -> [ReflectionQuestion] {
        _ = goalsTotal
        let seed = gateCount + focusMinutes + goalsCompleted

        let carryingTomorrow = forwardIntention.first { $0.text == "What are you carrying into tomorrow?" }!

        let q1: ReflectionQuestion
        if gateCount >= 5 {
            q1 = pick(from: focusAttention, seed: seed)
        } else if focusMinutes == 0 {
            q1 = pick(from: goalsExecution, seed: seed)
        } else if goalsCompleted == 0 {
            q1 = pick(from: energyState, seed: seed)
        } else if dayOfWeek == 6 {
            q1 = carryingTomorrow
        } else {
            q1 = pick(from: goalsExecution, seed: seed)
        }

        let pool = forwardIntention.filter { $0.id != q1.id }
        let idx2 = seed % max(pool.count, 1)
        var q2 = pool[idx2]
        if q2.id == q1.id, let alt = pool.first(where: { $0.id != q1.id }) {
            q2 = alt
        }
        return [q1, q2]
    }
}
