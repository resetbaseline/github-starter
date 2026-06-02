import SwiftUI

/// Final onboarding step — completes into the main app shell (after setup closing transition).
struct OnboardingScreen16: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        Color(hex: "#0A0A0A")
            .ignoresSafeArea()
            .onAppear(perform: completeOnboarding)
    }

    private func completeOnboarding() {
        let trimmed = onboarding.preferredName.trimmingCharacters(in: .whitespacesAndNewlines)
        auth.completeOnboarding(
            preferredName: trimmed.isEmpty ? nil : trimmed,
            wakeTime: onboarding.morningNotificationTime,
            checkInTime: onboarding.eveningCheckinTime,
            longTermGoals: onboarding.longTermGoalDrafts,
        )
    }
}
