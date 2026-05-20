import Combine
import Foundation
import SwiftUI
import UIKit

enum TimerState: Equatable {
    case idle
    case running
    case paused
    case completed
}

struct BlockedApp: Identifiable, Equatable {
    let id: UUID
    let name: String
    let colorHex: String
}

@MainActor
final class TimersViewModel: ObservableObject {
    @Published var selectedDuration: Int = 25
    @Published var customMinutes: Int = 45
    @Published var timerState: TimerState = .idle
    @Published var secondsRemaining: Int = 25 * 60
    @Published var secondsTotal: Int = 25 * 60
    @Published var hardLockActive: Bool = false
    @Published var debriefText: String = ""
    @Published var focusMinutesLoggedToday: Int = 32

    @Published private(set) var blockedApps: [BlockedApp] = [
        BlockedApp(id: UUID(), name: "Instagram", colorHex: "#E1306C"),
        BlockedApp(id: UUID(), name: "YouTube", colorHex: "#FF0000"),
        BlockedApp(id: UUID(), name: "X", colorHex: "#000000"),
        BlockedApp(id: UUID(), name: "WhatsApp", colorHex: "#25D366"),
    ]

    var progressFraction: Double {
        guard secondsTotal > 0 else { return 0 }
        let raw = Double(secondsTotal - secondsRemaining) / Double(secondsTotal)
        return min(1, max(0, raw))
    }

    var formattedTime: String {
        let minutes = secondsRemaining / 60
        let seconds = secondsRemaining % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    let presetDurations: [Int] = [5, 25, 60]

    private var countdownTimer: Timer?

    init() {
        syncDurationSeconds()
    }

    deinit {
        countdownTimer?.invalidate()
    }

    func selectPreset(_ minutes: Int) {
        selectedDuration = minutes
        if timerState == .idle {
            syncDurationSeconds()
        }
    }

    func adjustCustom(_ delta: Int) {
        customMinutes = min(180, max(1, customMinutes + delta))
        selectedDuration = customMinutes
        if timerState == .idle {
            syncDurationSeconds()
        }
    }

    func startSession() {
        secondsTotal = selectedDuration * 60
        secondsRemaining = secondsTotal
        debriefText = ""
        timerState = .running
        startCountdown()
    }

    func pauseSession() {
        timerState = .paused
        invalidateCountdown()
    }

    func resumeSession() {
        timerState = .running
        startCountdown()
    }

    func endSession() {
        invalidateCountdown()
        timerState = .idle
        syncDurationSeconds()
        debriefText = ""
    }

    func resetAfterComplete() {
        invalidateCountdown()
        timerState = .idle
        debriefText = ""
        syncDurationSeconds()
    }

    private func syncDurationSeconds() {
        let total = selectedDuration * 60
        secondsTotal = total
        secondsRemaining = total
    }

    private func startCountdown() {
        invalidateCountdown()
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
    }

    private func invalidateCountdown() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }

    private func tick() {
        guard timerState == .running else { return }
        guard secondsRemaining > 0 else {
            completeSession()
            return
        }
        secondsRemaining -= 1
        if secondsRemaining <= 0 {
            completeSession()
        }
    }

    private func completeSession() {
        invalidateCountdown()
        secondsRemaining = 0
        timerState = .completed
        debriefText = generateDebrief()
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }

    private func generateDebrief() -> String {
        if selectedDuration >= 25 {
            return "You did \(selectedDuration) minutes. No interruptions logged. That's a clean session."
        }
        if selectedDuration < 25 {
            return "Short session — \(selectedDuration) minutes. Still counts."
        }
        return "Session complete."
    }
}
