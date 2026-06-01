import SwiftUI

struct OnboardingScreen7: View {
    let onNext: () -> Void
    @ObservedObject var viewModel: OnboardingViewModel

    @State private var contentOpacity: Double = 0
    @State private var numberOpacity: Double = 0
    @State private var chevronOpacity: Double = 0
    @State private var numberWorkItem: DispatchWorkItem?
    @State private var chevronWorkItem: DispatchWorkItem?

    private var displayYears: Double {
        viewModel.yearsOnPhone > 0 ? viewModel.yearsOnPhone : 5.8
    }

    private var displayDays: Int {
        Int(displayYears * 365)
    }

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                OnboardingPhaseIndicator(activePhase: 1)
                    .padding(.top, 24)

                Spacer(minLength: 0)

                mainContent
                    .padding(.horizontal, 32)

                Spacer(minLength: 0)
            }

            VStack {
                Spacer()
                mountainLandscape
            }
            .allowsHitTesting(false)

            VStack(spacing: 12) {
                Spacer()

                Text("That's \(displayDays) days.")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color(hex: "#555555"))
                    .opacity(contentOpacity)

                Image(systemName: "chevron.down")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color(hex: "#444444"))
                    .opacity(chevronOpacity)
            }
            .padding(.bottom, 24)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if chevronOpacity > 0 {
                onNext()
            }
        }
        .onAppear(perform: startRevealSequence)
        .onDisappear(perform: cancelRevealSequence)
    }

    // MARK: - Content

    private var mainContent: some View {
        VStack(spacing: 0) {
            Text("THE REAL COST")
                .font(.system(size: 11, weight: .light))
                .foregroundStyle(Color(hex: "#8B7DFF"))
                .tracking(4)
                .padding(.top, 20)
                .opacity(contentOpacity)

            VStack(spacing: 0) {
                Text("At your current pace,")
                Text("you'll spend")
            }
            .font(.system(size: 22, weight: .light, design: .serif))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.top, 16)
            .opacity(contentOpacity)

            VStack(spacing: 4) {
                Text(String(format: "%.1f", displayYears))
                    .font(.system(size: 120, weight: .light, design: .serif))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
                    .shadow(color: Color(hex: "#9B7FD4").opacity(0.3), radius: 12, x: 0, y: 0)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                Text("YEARS")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
                    .kerning(6)
                    .shadow(color: Color(hex: "#9B7FD4").opacity(0.3), radius: 8, x: 0, y: 0)
            }
            .opacity(numberOpacity)
            .padding(.top, 12)

            VStack(spacing: 0) {
                Text("of your life")
                Text("on your phone.")
            }
            .font(.system(size: 22, weight: .light, design: .serif))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .padding(.top, 16)
            .opacity(contentOpacity)

            Text("Scrolling. Switching. Consuming.")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .multilineTextAlignment(.center)
                .padding(.top, 12)
                .opacity(contentOpacity)
        }
        .frame(maxWidth: .infinity)
    }

    private var mountainLandscape: some View {
        Canvas { context, size in
            var mainPeak = Path()
            mainPeak.move(to: CGPoint(x: 0, y: size.height))
            mainPeak.addLine(to: CGPoint(x: size.width * 0.3, y: size.height * 0.3))
            mainPeak.addLine(to: CGPoint(x: size.width * 0.55, y: size.height * 0.6))
            mainPeak.addLine(to: CGPoint(x: size.width, y: size.height))
            context.fill(mainPeak, with: .color(Color(hex: "#0D0D0D")))

            var leftRidge = Path()
            leftRidge.move(to: CGPoint(x: 0, y: size.height))
            leftRidge.addLine(to: CGPoint(x: size.width * 0.15, y: size.height * 0.55))
            leftRidge.addLine(to: CGPoint(x: size.width * 0.35, y: size.height * 0.7))
            leftRidge.addLine(to: CGPoint(x: 0, y: size.height))
            context.fill(leftRidge, with: .color(Color(hex: "#0C0C0C")))

            let glowRect = CGRect(x: 0, y: size.height * 0.7, width: size.width, height: size.height * 0.3)
            context.fill(
                Path(glowRect),
                with: .linearGradient(
                    Gradient(colors: [
                        Color(hex: "#1A0A2E").opacity(0.15),
                        Color.clear,
                    ]),
                    startPoint: CGPoint(x: size.width / 2, y: size.height * 0.7),
                    endPoint: CGPoint(x: size.width / 2, y: size.height * 0.5),
                ),
            )
        }
        .frame(maxWidth: .infinity)
        .frame(height: UIScreen.main.bounds.height * 0.28)
    }

    // MARK: - Animation

    private func startRevealSequence() {
        cancelRevealSequence()

        withAnimation(.easeInOut(duration: 1.5)) {
            contentOpacity = 1.0
        }

        let numberItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 1.2)) {
                numberOpacity = 1.0
            }
        }
        numberWorkItem = numberItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5, execute: numberItem)

        let chevronItem = DispatchWorkItem {
            withAnimation(.easeInOut(duration: 0.8)) {
                chevronOpacity = 1.0
            }
        }
        chevronWorkItem = chevronItem
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0, execute: chevronItem)
    }

    private func cancelRevealSequence() {
        numberWorkItem?.cancel()
        chevronWorkItem?.cancel()
        numberWorkItem = nil
        chevronWorkItem = nil
    }
}
