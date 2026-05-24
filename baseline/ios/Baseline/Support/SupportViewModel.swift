import Combine
import Foundation
import SwiftUI
import UIKit

enum SupportCategory: String, CaseIterable, Identifiable {
    case bugReport
    case featureRequest
    case accountIssue
    case generalFeedback
    case betaFeedback
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .bugReport: "Bug report"
        case .featureRequest: "Feature request"
        case .accountIssue: "Account issue"
        case .generalFeedback: "General feedback"
        case .betaFeedback: "Beta feedback"
        case .other: "Other"
        }
    }

    var emoji: String {
        switch self {
        case .bugReport: "🐛"
        case .featureRequest: "💡"
        case .accountIssue: "👤"
        case .generalFeedback: "💬"
        case .betaFeedback: "🧪"
        case .other: "💭"
        }
    }
}

struct SupportMessage: Identifiable, Equatable {
    enum Role: Equatable {
        case user
        case bot
        case escalatePrompt
    }

    let id: UUID
    let role: Role
    let text: String

    init(id: UUID = UUID(), role: Role, text: String) {
        self.id = id
        self.role = role
        self.text = text
    }
}

@MainActor
final class SupportViewModel: ObservableObject {
    @Published var selectedCategory: SupportCategory?
    @Published var messages: [SupportMessage] = []
    @Published var userInput: String = ""
    @Published var isTyping: Bool = false
    @Published var showForm: Bool = false
    @Published var formText: String = ""
    @Published var selectedScreenshot: UIImage?
    @Published var isSubmitting: Bool = false
    @Published var isSubmitted: Bool = false

    private var botTask: Task<Void, Never>?

    var deviceInfo: [String: String] {
        [
            "model": UIDevice.current.model,
            "systemVersion": UIDevice.current.systemVersion,
            "appVersion": appVersion,
        ]
    }

    var appVersion: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String
        if let build, !build.isEmpty {
            return "\(version) (\(build))"
        }
        return version
    }

    func applyInitialCategory(_ category: SupportCategory?) {
        guard let category, selectedCategory == nil else { return }
        selectCategory(category)
    }

    func selectCategory(_ cat: SupportCategory) {
        botTask?.cancel()
        selectedCategory = cat
        messages = []
        showForm = false
        formText = ""
        selectedScreenshot = nil
        isSubmitted = false
        isSubmitting = false
        userInput = ""

        messages.append(SupportMessage(role: .bot, text: "Hey — thanks for getting in touch."))
        isTyping = true

        botTask = Task {
            try? await Task.sleep(nanoseconds: 800_000_000)
            guard !Task.isCancelled else { return }
            messages.append(SupportMessage(role: .bot, text: openingQuestion(for: cat)))
            isTyping = false
        }
    }

    func sendUserMessage() {
        let trimmed = userInput.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !isTyping else { return }

        messages.append(SupportMessage(role: .user, text: trimmed))
        userInput = ""
        isTyping = true

        botTask?.cancel()
        botTask = Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            guard !Task.isCancelled else { return }

            let botResult = generateBotResponse(text: trimmed)
            messages.append(SupportMessage(role: .bot, text: botResult.response))

            let formAlreadyVisible = showForm
            if botResult.showForm {
                showForm = true
            }

            if !botResult.resolved && !formAlreadyVisible && !botResult.showForm {
                messages.append(SupportMessage(role: .escalatePrompt, text: "This didn't help →"))
            }

            isTyping = false
        }
    }

    func showEscalationForm() {
        showForm = true
    }

    func submitForm(userId: String = "00000000-0000-0000-0000-000000000000") {
        let trimmed = formText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isSubmitting = true

        Task {
            var screenshotBase64: String?
            if let image = selectedScreenshot, let data = image.jpegData(compressionQuality: 0.85) {
                screenshotBase64 = data.base64EncodedString()
            }

            let payload: [String: Any] = [
                "userId": userId,
                "category": selectedCategory?.displayName ?? SupportCategory.other.displayName,
                "message": trimmed,
                "deviceInfo": deviceInfo,
                "appVersion": appVersion,
                "resolvedByBot": false,
                "screenshotBase64": screenshotBase64 as Any,
            ]

            // TODO: wire to Supabase edge function when auth session is available.
            let endpoint = SupabaseBootstrap.supabaseURL
                .appendingPathComponent("functions/v1/send-support-email")
            print("send-support-email stub → \(endpoint.absoluteString)")
            print(String(data: (try? JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted])) ?? Data(), encoding: .utf8) ?? "{}")

            try? await Task.sleep(nanoseconds: 1_000_000_000)

            isSubmitting = false
            isSubmitted = true
        }
    }

    func generateBotResponse(text: String) -> (response: String, resolved: Bool, showForm: Bool) {
        let lower = text.lowercased()

        if lower.contains("goal") || lower.contains("add") {
            return (
                "Tap the '+' button at the bottom of the Non-Negotiables section on the home screen. The Coach Assist button will help you turn any idea into a specific daily action.",
                true,
                false,
            )
        }

        if lower.contains("streak"), lower.contains("reset") || lower.contains("lost") {
            return (
                "Streaks reset when a day is classified as 'Light' — meaning no goals were marked complete and no reflection was submitted. If you completed goals but your streak reset, that's a bug — tap 'This didn't help' to report it.",
                false,
                false,
            )
        }

        if lower.contains("gate") {
            return (
                "The Gate system is currently in development. For now you can test it using the Test Gate button on the home screen. Full app blocking launches in a future update.",
                true,
                false,
            )
        }

        if lower.contains("check"), lower.contains("in") {
            return (
                "Check-in is always available from the home screen — tap the Check In card at the bottom. There's no time restriction in the current version.",
                true,
                false,
            )
        }

        if lower.contains("crash") || lower.contains("bug") || lower.contains("broken") || lower.contains("not working") {
            return (
                "That sounds like a bug. Let me get the details to our team.",
                false,
                true,
            )
        }

        return (
            "I'm not sure I can help with that directly. Let me connect you with the team.",
            false,
            true,
        )
    }

    private func openingQuestion(for category: SupportCategory) -> String {
        switch category {
        case .bugReport:
            "Sorry to hear something's not working. Can you describe what happened?"
        case .featureRequest:
            "Love that you're thinking about the product. What would you like to see?"
        case .accountIssue:
            "Let's sort this out. What's going on with your account?"
        case .generalFeedback:
            "Appreciate you sharing. What's on your mind?"
        case .betaFeedback:
            "Perfect timing — beta feedback helps a lot. What did you notice?"
        case .other:
            "Go ahead — what's on your mind?"
        }
    }
}
