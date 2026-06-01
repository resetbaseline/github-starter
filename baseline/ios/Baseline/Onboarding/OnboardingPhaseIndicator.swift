import SwiftUI

struct OnboardingPhaseIndicator: View {
    let activePhase: Int

    private let phases = ["You", "Your Time", "Your Goals", "Your Systems", "Setup"]

    var body: some View {
        HStack(spacing: 8) {
            ForEach(Array(phases.enumerated()), id: \.offset) { index, label in
                VStack(spacing: 5) {
                    Capsule()
                        .fill(index == activePhase ? Color(hex: "#8B7DFF") : Color(hex: "#1E1E1E"))
                        .frame(width: 32, height: 5)

                    Text(label)
                        .font(.system(size: 9, weight: .light))
                        .foregroundStyle(Color(hex: "#444444"))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(width: 32)
                }
            }
        }
    }
}
