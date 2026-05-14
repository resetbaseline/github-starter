import SwiftUI

struct OnboardingScreen3: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        OnboardingContentPage(
            stepLabel: onboarding.stepLabel(forPage: 2),
            headline: "Coach reads your day",
            subheadline: "After check-in, the coach note uses your goals, focus minutes, and Gate activity—specific to you, not a template.",
            bullets: [
                "Short nightly note tied to what you logged",
                "Memory carries context across sessions",
                "You can always steer it back to one next step",
            ]
        )
    }
}
