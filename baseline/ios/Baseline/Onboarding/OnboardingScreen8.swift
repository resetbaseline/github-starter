import SwiftUI

struct OnboardingScreen8: View {
    let onNext: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingPhaseIndicator(activePhase: 1)
                    .padding(.top, 24)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 0) {
                        logoMark
                            .padding(.top, 48)

                        headline
                            .padding(.top, 24)

                        Text("Baseline helps you reclaim it.")
                            .font(.system(size: 16, weight: .light))
                            .foregroundStyle(Color(hex: "#888888"))
                            .multilineTextAlignment(.center)
                            .padding(.top, 12)
                            .padding(.horizontal, 32)

                        valueProps
                            .padding(.top, 32)
                            .padding(.horizontal, 40)

                        Spacer(minLength: 120)
                    }
                    .frame(maxWidth: .infinity)
                }

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }

            VStack {
                Spacer()
                mountainLandscape
            }
            .allowsHitTesting(false)
        }
        .opacity(opacity)
        .onAppear {
            onboarding.markReframeSeen()
            withAnimation(.easeInOut(duration: 0.6)) {
                opacity = 1.0
            }
        }
    }

    // MARK: - Logo

    private var logoMark: some View {
        Circle()
            .fill(Theme.Logo.color)
            .frame(width: 40, height: 40)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Headline

    private var headline: some View {
        VStack(spacing: 4) {
            Text("That's enough time")
                .foregroundStyle(Color.white)
            Text("to completely")
                .foregroundStyle(Color.white)
            Text("change your life.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        }
        .font(.system(size: 30, weight: .light, design: .serif))
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }

    // MARK: - Value props

    private var valueProps: some View {
        VStack(alignment: .leading, spacing: 24) {
            ValuePropRow(
                symbolName: "shield",
                label: "Protect your attention",
                sublabel: "Block distractions before they take over.",
            )
            ValuePropRow(
                symbolName: "arrow.up.right",
                label: "Build daily traction",
                sublabel: "Small consistent actions compound over time.",
            )
            ValuePropRow(
                symbolName: "waveform.path.ecg",
                label: "Understand your patterns",
                sublabel: "Your coach learns how you operate and adapts.",
            )
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Bottom

    private var bottomSection: some View {
        VStack(spacing: 8) {
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

            Text("You're about to take back your time.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Mountain

    private var mountainLandscape: some View {
        Canvas { context, size in
            var peak1 = Path()
            peak1.move(to: CGPoint(x: 0, y: size.height))
            peak1.addLine(to: CGPoint(x: size.width * 0.12, y: size.height * 0.72))
            peak1.addLine(to: CGPoint(x: size.width * 0.22, y: size.height * 0.45))
            peak1.addLine(to: CGPoint(x: size.width * 0.38, y: size.height * 0.58))
            peak1.addLine(to: CGPoint(x: size.width * 0.52, y: size.height * 0.28))
            peak1.addLine(to: CGPoint(x: size.width * 0.68, y: size.height * 0.52))
            peak1.addLine(to: CGPoint(x: size.width * 0.82, y: size.height * 0.38))
            peak1.addLine(to: CGPoint(x: size.width * 0.94, y: size.height * 0.62))
            peak1.addLine(to: CGPoint(x: size.width, y: size.height * 0.48))
            peak1.addLine(to: CGPoint(x: size.width, y: size.height))
            peak1.closeSubpath()
            context.fill(peak1, with: .color(Color(hex: "#0D0D0D")))

            var peak2 = Path()
            peak2.move(to: CGPoint(x: 0, y: size.height))
            peak2.addLine(to: CGPoint(x: size.width * 0.08, y: size.height * 0.55))
            peak2.addLine(to: CGPoint(x: size.width * 0.18, y: size.height * 0.68))
            peak2.addLine(to: CGPoint(x: size.width * 0.28, y: size.height * 0.82))
            peak2.addLine(to: CGPoint(x: 0, y: size.height))
            peak2.closeSubpath()
            context.fill(peak2, with: .color(Color(hex: "#111111")))

            var peak3 = Path()
            peak3.move(to: CGPoint(x: size.width * 0.58, y: size.height))
            peak3.addLine(to: CGPoint(x: size.width * 0.72, y: size.height * 0.75))
            peak3.addLine(to: CGPoint(x: size.width * 0.88, y: size.height * 0.88))
            peak3.addLine(to: CGPoint(x: size.width, y: size.height))
            peak3.addLine(to: CGPoint(x: size.width * 0.58, y: size.height))
            peak3.closeSubpath()
            context.fill(peak3, with: .color(Color(hex: "#0F0F0F")))
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.28)
        .mask(mountainTopFadeMask)
    }

    private var mountainTopFadeMask: some View {
        GeometryReader { geo in
            let fadeHeight = min(40, geo.size.height)

            VStack(spacing: 0) {
                LinearGradient(
                    colors: [.clear, .black],
                    startPoint: .top,
                    endPoint: .bottom,
                )
                .frame(height: fadeHeight)

                Rectangle()
                    .fill(Color.black)
            }
            .frame(height: geo.size.height)
        }
    }
}

// MARK: - Value prop row

private struct ValuePropRow: View {
    let symbolName: String
    let label: String
    let sublabel: String

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ZStack {
                Circle()
                    .stroke(Color(hex: "#2A2A2A"), lineWidth: 1)
                    .frame(width: 40, height: 40)

                Image(systemName: symbolName)
                    .font(.system(size: 16, weight: .thin))
                    .foregroundStyle(Color(hex: "#8B7DFF"))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundStyle(Color.white)

                Text(sublabel)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(Color(hex: "#555555"))
            }

            Spacer(minLength: 0)
        }
    }
}
