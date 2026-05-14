import SwiftUI

struct OnboardingScreen4: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        OnboardingContentPage(
            stepLabel: onboarding.stepLabel(forPage: 3),
            headline: "Rhythm beats intensity",
            subheadline: "Baseline is built around one day at a time: goals, timers, check-in, then tomorrow’s intention—small loops you can repeat.",
            bullets: [
                "Check-in captures outcomes and reflections once",
                "Tomorrow’s intention carries forward without replanning from scratch",
                "Timers keep focus blocks honest and visible",
            ]
        )
    }
}
