import Combine
import Foundation
import SwiftUI

enum GateReason: String, CaseIterable, Identifiable {
    case boredom
    case procrastinating
    case socialCheck
    case news
    case genuineNeed
    case habit
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .boredom: "I'm bored"
        case .procrastinating: "Avoiding something"
        case .socialCheck: "Quick social check"
        case .news: "Checking news"
        case .genuineNeed: "I actually need this"
        case .habit: "Pure habit — no reason"
        case .other: "Other"
        }
    }
}

enum GateConversationStep: Equatable {
    case reasonPicking
    case coachChallenge
    case coachSecondChallenge
    case validated
    case openAnyway
}

enum GateOutcome: Equatable {
    case none
    case letThrough
    case redirected
    case closed
    case openAnyway
}

@MainActor
final class GateViewModel: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var blockedAppName: String = "Instagram"
    @Published var selectedReason: GateReason?
    @Published var conversationStep: GateConversationStep = .reasonPicking
    @Published var userResponse: String = ""
    @Published var secondUserResponse: String = ""
    @Published var otherReason: String = ""
    @Published var gateOutcome: GateOutcome = .none
    @Published var triggerCount: Int = 4
    @Published var streakAtRisk: Bool = false

    @AppStorage("baseline.emergencyExits") var emergencyExitsRemaining: Int = 3

    var intentionQuestion: String {
        "Why are you opening \(blockedAppName) right now?"
    }

    var coachChallenge: String {
        guard let reason = selectedReason else { return "" }
        switch reason {
        case .boredom:
            return "What's the first thing you'd do right now if you put the phone down?"
        case .procrastinating:
            return "What specifically are you avoiding?"
        case .socialCheck:
            return "Who are you expecting to hear from?"
        case .news:
            return "Is there something specific you're worried about?"
        case .genuineNeed:
            return "What exactly do you need to do on there?"
        case .habit:
            return "If you had to guess — what triggered this impulse just now?"
        case .other:
            return "Tell me more — what's going on?"
        }
    }

    var coachSecondChallenge: String {
        guard let reason = selectedReason else { return "" }
        switch reason {
        case .boredom:
            return "Scrolling trades 30 seconds of boredom for 20 minutes of numbness. What would actually help right now?"
        case .procrastinating:
            return "Scrolling won't shrink the task. What's the smallest possible first step on what you're avoiding?"
        case .socialCheck:
            return "If they haven't messaged you yet, they will. Can it wait 90 minutes?"
        case .news:
            return "The news will still be there in two hours. Will your work?"
        case .genuineNeed:
            return "That sounds specific enough. Go do just that — nothing else."
        case .habit:
            return "Pure habit is the most honest answer. That awareness is the Gate working. Close it."
        case .other:
            return "Whatever's going on — Instagram isn't the answer to it. What would actually help?"
        }
    }

    var isValidated: Bool {
        let response = userResponse.lowercased()
        let signals = [
            "my mom", "my dad", "my client", "my friend", "my boss",
            "dm", "message",
            "client", "work", "project", "deadline", "email",
            "i know", "i'm choosing", "im choosing", "i own this", "aware",
        ]
        if signals.contains(where: { response.contains($0) }) {
            return true
        }
        if selectedReason == .genuineNeed && userResponse.count > 15 {
            return true
        }
        return false
    }

    func selectReason(_ reason: GateReason) {
        selectedReason = reason
        if reason == .other && otherReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            conversationStep = .reasonPicking
        } else {
            conversationStep = .coachChallenge
        }
    }

    func advanceFromOtherReasonIfReady() {
        guard selectedReason == .other else { return }
        guard !otherReason.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        conversationStep = .coachChallenge
    }

    func submitUserResponse() {
        if isValidated {
            conversationStep = .validated
        } else {
            conversationStep = .coachSecondChallenge
        }
    }

    func submitSecondResponse() {
        conversationStep = .validated
    }

    func letMeThrough() {
        gateOutcome = .letThrough
        triggerCount += 1
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            isPresented = false
        }
    }

    func redirect() {
        gateOutcome = .redirected
        isPresented = false
    }

    func closeGate() {
        gateOutcome = .closed
        isPresented = false
    }

    func openAnyway() {
        gateOutcome = .openAnyway
        isPresented = false
    }

    func useEmergencyExit() {
        emergencyExitsRemaining = max(0, emergencyExitsRemaining - 1)
        gateOutcome = .letThrough
        Task {
            try? await Task.sleep(nanoseconds: 300_000_000)
            isPresented = false
        }
    }

    func resetGate() {
        selectedReason = nil
        conversationStep = .reasonPicking
        userResponse = ""
        secondUserResponse = ""
        otherReason = ""
        gateOutcome = .none
    }
}
