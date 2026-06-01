import SwiftUI

struct OnboardingScreen13: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        headline
                            .padding(.top, 48)

                        coachIcon
                            .frame(maxWidth: .infinity)
                            .padding(.top, 32)

                        personalizedLine
                            .padding(.top, 20)

                        capabilityRows
                            .padding(.top, 32)

                        privacyLine
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
            Text("Meet your\n")
                .foregroundStyle(Color.white)
            + Text("coach.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var coachIcon: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(hex: "#3D2070").opacity(0.3),
                            Color.clear,
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100,
                    ),
                )
                .frame(width: 200, height: 200)

            Circle()
                .fill(Color(hex: "#0D0D0D"))
                .overlay(
                    Circle()
                        .stroke(Color(hex: "#2A2A2A"), lineWidth: 1),
                )
                .frame(width: 100, height: 100)

            CoachPeakIcon(size: 48)
        }
        .frame(width: 200, height: 200)
    }

    private var personalizedLine: some View {
        (
            Text("Your coach is already ")
                .foregroundStyle(Color.white)
            + Text("learning")
                .foregroundStyle(Color(hex: "#8B7DFF"))
            + Text(" how you operate.")
                .foregroundStyle(Color.white)
        )
        .font(.system(size: 18, weight: .light, design: .serif))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity)
    }

    private var capabilityRows: some View {
        VStack(alignment: .leading, spacing: 20) {
            CoachCapabilityRow(
                symbolName: "bubble.left.and.bubble.right",
                category: "OBSERVATION",
                message: "You've been most consistent when you work before noon. Let's protect that.",
            )
            CoachCapabilityRow(
                symbolName: "arrow.up.right",
                category: "GOAL REMINDER",
                message: "You said you wanted to run a half marathon. Your next run is tomorrow.",
            )
            CoachCapabilityRow(
                symbolName: "person.crop.circle",
                category: "IDENTITY REFLECTION",
                message: "You've shown up 11 days straight. That's not a streak — that's who you're becoming.",
            )
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var privacyLine: some View {
        HStack(spacing: 6) {
            Image(systemName: "lock")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color(hex: "#444444"))
            Text("Powered by Claude. Private by design.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#444444"))
        }
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

// MARK: - Capability row

private struct CoachCapabilityRow: View {
    let symbolName: String
    let category: String
    let message: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: symbolName)
                .font(.system(size: 20, weight: .thin))
                .foregroundStyle(Color(hex: "#8B7DFF"))
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 4) {
                Text(category)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Color(hex: "#444444"))
                    .tracking(1)

                Text(message)
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color(hex: "#CCCCCC"))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
