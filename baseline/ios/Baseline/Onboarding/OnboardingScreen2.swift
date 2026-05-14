import SwiftUI

struct OnboardingScreen2: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        OnboardingContentPage(
            stepLabel: onboarding.stepLabel(forPage: 1),
            headline: "Gate is friction on purpose",
            subheadline: "When you open something that competes with your plan, Gate asks for a reason and a time box—so slips are visible, not hidden.",
            bullets: [
                "You choose how strict Gate is for each app or site",
                "Time granted is real: when it ends, Gate checks back in",
                "Patterns show up in your week without judgment",
            ]
        )
    }
}
