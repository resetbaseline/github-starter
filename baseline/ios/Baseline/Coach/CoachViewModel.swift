import Combine
import Foundation
import SwiftUI

enum CoachRole: String, Equatable {
    case user
    case coach
}

enum CoachSessionType: String, CaseIterable, Identifiable {
    case freeform
    case stuck
    case planTomorrow
    case checkIn

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .freeform: "Freeform"
        case .stuck: "I'm Stuck"
        case .planTomorrow: "Plan Tomorrow"
        case .checkIn: "Check-in"
        }
    }

    var openingMessage: String {
        switch self {
        case .freeform:
            "You got the two that mattered yesterday. Low energy, some scrolling — honest day. What's on your mind today?"
        case .stuck:
            "Tell me what's stuck. One sentence is enough — I have your context from the last 7 days."
        case .planTomorrow:
            "Let's set up tomorrow. What's the one thing that must happen no matter what?"
        case .checkIn:
            "Ready to close the loop on today. How did it go with your non-negotiables?"
        }
    }
}

struct CoachMessage: Identifiable, Equatable {
    let id: UUID
    let role: CoachRole
    let text: String
    let timestamp: Date
}

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var messages: [CoachMessage] = []
    @Published var sessionType: CoachSessionType = .freeform
    @Published var isTyping = false
    @Published var draftMessage = ""

    let sessionTypes: [CoachSessionType] = CoachSessionType.allCases

    init() {
        selectSessionType(.freeform)
    }

    func selectSessionType(_ type: CoachSessionType) {
        sessionType = type
        messages = []
        isTyping = false
        messages.append(
            CoachMessage(
                id: UUID(),
                role: .coach,
                text: type.openingMessage,
                timestamp: Date(),
            ),
        )
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(
            CoachMessage(
                id: UUID(),
                role: .user,
                text: trimmed,
                timestamp: Date(),
            ),
        )
        draftMessage = ""
        isTyping = true

        Task {
            try? await Task.sleep(nanoseconds: 1_200_000_000)
            isTyping = false
            messages.append(
                CoachMessage(
                    id: UUID(),
                    role: .coach,
                    text: "Got it. This is where the coach-message Edge Function will respond when Supabase is wired.",
                    timestamp: Date(),
                ),
            )
        }
    }
}
