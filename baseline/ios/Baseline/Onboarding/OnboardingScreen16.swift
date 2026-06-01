import SwiftUI

/// Screen 16 placeholder — transitions into the main app after setup completes.
struct OnboardingScreen16: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        Color(hex: "#0A0A0A")
            .ignoresSafeArea()
            .task {
                enterApp()
            }
    }

    private func enterApp() {
        let trimmed = onboarding.preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
        auth.completeOnboarding(
            preferredName: trimmed.isEmpty ? nil : trimmed,
            wakeTime: onboarding.morningNotificationTime,
            checkInTime: onboarding.eveningCheckinTime,
            longTermGoals: onboarding.longTermGoalDrafts,
        )
    }
}
