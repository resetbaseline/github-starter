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

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .boredom: "I'm bored"
        case .procrastinating: "Avoiding something"
        case .socialCheck: "Quick social check"
        case .news: "Checking news"
        case .genuineNeed: "I actually need this"
        case .habit: "Pure habit — no reason"
        }
    }
}

enum GateOutcome: Equatable {
    case none
    case letThrough
    case redirected
    case closed
}

@MainActor
final class GateViewModel: ObservableObject {
    @Published var isPresented: Bool = false
    @Published var blockedAppName: String = "Instagram"
    @Published var selectedReason: GateReason?
    @Published var customReason: String = ""
    @Published var gateOutcome: GateOutcome = .none
    @Published var triggerCount: Int = 4
    @Published var streakAtRisk: Bool = false

    var intentionQuestion: String {
        "Why are you opening \(blockedAppName) right now?"
    }

    var coachResponse: String {
        guard let reason = selectedReason else { return "" }
        switch reason {
        case .boredom:
            return "Boredom is a signal. What were you supposed to be doing?"
        case .procrastinating:
            return "You're avoiding something. The task won't shrink by scrolling."
        case .socialCheck:
            return "One check becomes twenty minutes. You know this."
        case .news:
            return "News will still be there in two hours. Will your work?"
        case .genuineNeed:
            return "Alright — you have a reason. Keep it to 5 minutes."
        case .habit:
            return "Pure habit. That's the most honest answer. Close the app."
        }
    }

    func selectReason(_ reason: GateReason) {
        selectedReason = reason
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

    func resetGate() {
        selectedReason = nil
        customReason = ""
        gateOutcome = .none
    }
}
