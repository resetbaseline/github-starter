import SwiftUI

struct OnboardingScreen14: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var opacity: Double = 0

    private let moments: [RhythmMoment] = [
        RhythmMoment(
            timeLabel: "Morning",
            timeLabelColor: Color(hex: "#8B7DFF"),
            symbolName: "sun.horizon",
            title: "Your anchor arrives.",
            description: "One notification. Your most important action for the day.",
        ),
        RhythmMoment(
            timeLabel: "During the day",
            timeLabelColor: Color(hex: "#444444"),
            symbolName: "hourglass",
            title: "The Gate protects your focus.",
            description: "When you drift toward distractions, The Gate steps in.",
        ),
        RhythmMoment(
            timeLabel: "Anytime",
            timeLabelColor: Color(hex: "#444444"),
            symbolName: "timer",
            title: "Focus sessions build momentum.",
            description: "Short deep work blocks. No phone. Just progress.",
        ),
        RhythmMoment(
            timeLabel: "Evening",
            timeLabelColor: Color(hex: "#444444"),
            symbolName: "moon",
            title: "Check in with your coach.",
            description: "A brief reflection — your coach adapts for tomorrow.",
        ),
        RhythmMoment(
            timeLabel: "Every day",
            timeLabelColor: Color(hex: "#8B7DFF"),
            symbolName: "flame",
            title: "Your streak grows.",
            description: "Complete an anchor, a focus session, or your check-in. Any one counts.",
        ),
    ]

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headline
                            .padding(.top, 48)

                        subtitle
                            .padding(.top, 10)

                        RhythmTimelineView(moments: moments)
                            .padding(.top, 32)

                        closingLine
                            .padding(.top, 32)
                            .padding(.bottom, 16)
                    }
                }

                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.6)) {
                opacity = 1.0
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 3)

            HStack {
                Button(action: onBack) {
                    Text("‹")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color(hex: "#555555"))
                        .frame(width: 32, height: 32, alignment: .leading)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Content

    private var headline: some View {
        (
            Text("Your daily\n")
                .foregroundStyle(Color.white)
            + Text("rhythm.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var subtitle: some View {
        Text("Every day with Baseline follows the same quiet loop.")
            .font(.system(size: 15, weight: .light))
            .foregroundStyle(Color(hex: "#555555"))
            .multilineTextAlignment(.leading)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var closingLine: some View {
        (
            Text("Simple. Consistent. ")
                .foregroundStyle(Color.white)
            + Text("Yours.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.custom("NewYorkSmall-Light", size: 18))
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    private var continueButton: some View {
        Button(action: onNext) {
            Text("Continue →")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#7C5CBF"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Timeline

private struct RhythmMoment {
    let timeLabel: String
    let timeLabelColor: Color
    let symbolName: String
    let title: String
    let description: String
}

private struct RhythmTimelineView: View {
    let moments: [RhythmMoment]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(Array(moments.enumerated()), id: \.offset) { index, moment in
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 0) {
                        Rectangle()
                            .fill(Color(hex: "#1E1E1E"))
                            .frame(width: 1, height: index == 0 ? 0 : 16)

                        ZStack {
                            Circle()
                                .fill(Color(hex: "#111111"))
                                .overlay(
                                    Circle()
                                        .stroke(Color(hex: "#2A2A2A"), lineWidth: 1),
                                )
                                .frame(width: 36, height: 36)

                            Image(systemName: moment.symbolName)
                                .font(.system(size: 16, weight: .thin))
                                .foregroundStyle(Color(hex: "#8B7DFF"))
                        }

                        Rectangle()
                            .fill(Color(hex: "#1E1E1E"))
                            .frame(width: 1, height: index == moments.count - 1 ? 0 : 28)
                    }
                    .frame(width: 36)

                    VStack(alignment: .leading, spacing: 3) {
                        Text(moment.timeLabel)
                            .font(.system(size: 12, weight: .light))
                            .foregroundStyle(moment.timeLabelColor)

                        Text(moment.title)
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(.white)

                        Text(moment.description)
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.top, index == 0 ? 0 : 16)
                    .padding(.bottom, 8)

                    Spacer(minLength: 0)
                }
            }
        }
        .padding(.horizontal, 40)
    }
}
