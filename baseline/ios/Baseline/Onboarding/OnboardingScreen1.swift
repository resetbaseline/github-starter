import SwiftUI

struct OnboardingScreen1: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        OnboardingContentPage(
            stepLabel: onboarding.stepLabel(forPage: 0),
            headline: "Welcome to Baseline",
            subheadline: "A single place to plan your day, protect focus, and close the loop with a short check-in.",
            bullets: [
                "Set a small set of goals you can actually finish",
                "See streaks and rhythm as feedback—not a scoreboard",
                "End the day with reflection the coach can use tomorrow",
            ]
        )
    }
}
