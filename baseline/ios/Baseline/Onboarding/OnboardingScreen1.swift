import SwiftUI

struct OnboardingScreen1: View {
    let onNext: () -> Void

    @State private var mountainOpacity: Double = 0
    @State private var glowOpacity: Double = 0
    @State private var logoOpacity: Double = 0
    @State private var logoOffset: CGFloat = -6
    @State private var wordmarkOpacity: Double = 0
    @State private var line1Opacity: Double = 0
    @State private var line2Opacity: Double = 0
    @State private var buttonOpacity: Double = 0
    @State private var glowPulse: Bool = false

    @State private var pendingWorkItems: [DispatchWorkItem] = []

    var body: some View {
        GeometryReader { geo in
            let mountainHeight = geo.size.height * 0.42

            ZStack {
                Color(hex: "#0A0A0A")
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    logoSection
                        .padding(.top, 60)

                    Spacer(minLength: 0)

                    mountainSection(height: mountainHeight)

                    quoteSection
                        .padding(.top, 32)

                    Spacer(minLength: 0)

                    bottomSection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)
                }
            }
        }
        .onAppear(perform: startAnimationSequence)
        .onDisappear(perform: cancelPendingAnimations)
    }

    // MARK: - Sections

    private var logoSection: some View {
        VStack(spacing: 10) {
            Circle()
                .fill(Theme.Logo.color)
                .frame(width: Theme.Logo.diameter, height: Theme.Logo.diameter)
                .opacity(logoOpacity)
                .offset(y: logoOffset)

            Text("BASELINE")
                .font(.system(size: 11, weight: .thin, design: .default))
                .tracking(8)
                .foregroundStyle(Color(hex: "#8B7DFF"))
                .opacity(wordmarkOpacity)
        }
        .frame(maxWidth: .infinity)
    }

    private func mountainSection(height: CGFloat) -> some View {
        ZStack {
            RadialGradient(
                colors: [
                    Color(hex: "#6B3FA0"),
                    Color(hex: "#6B3FA0").opacity(0),
                ],
                center: UnitPoint(x: 0.48, y: 0.22),
                startRadius: 0,
                endRadius: 120,
            )
            .opacity(glowPulse ? 0.83 : glowOpacity)
            .blur(radius: 8)

            OnboardingSplashMountain()
                .opacity(mountainOpacity)
                .mask(mountainBaseMask)
        }
        .frame(height: height)
        .frame(maxWidth: .infinity)
    }

    private var mountainBaseMask: LinearGradient {
        LinearGradient(
            stops: [
                .init(color: .white, location: 0),
                .init(color: .white, location: 0.7),
                .init(color: .clear, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom,
        )
    }

    private var quoteSection: some View {
        VStack(spacing: 10) {
            Text("You don't need more motivation.")
                .font(.system(size: 19, weight: .light, design: .serif))
                .foregroundStyle(Color(hex: "#FFFFFF"))
                .multilineTextAlignment(.center)
                .opacity(line1Opacity)

            Text("You need a baseline.")
                .font(.system(size: 26, weight: .light, design: .serif))
                .foregroundStyle(Color(hex: "#8B7DFF"))
                .multilineTextAlignment(.center)
                .opacity(line2Opacity)
        }
        .padding(.horizontal, 28)
        .frame(maxWidth: .infinity)
    }

    private var bottomSection: some View {
        VStack(spacing: 28) {
            pageIndicatorDots

            Button(action: onNext) {
                HStack(spacing: 6) {
                    Text("Begin")
                        .font(.system(size: 17, weight: .regular, design: .default))
                    Text("→")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#7C5CBF"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
        }
        .opacity(buttonOpacity)
    }

    private var pageIndicatorDots: some View {
        HStack(spacing: 6) {
            Capsule()
                .fill(Color(hex: "#8B7DFF"))
                .frame(width: 16, height: 6)

            ForEach(0 ..< 3, id: \.self) { _ in
                Circle()
                    .fill(Color(hex: "#2A2A2A"))
                    .frame(width: 6, height: 6)
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Animation

    private func startAnimationSequence() {
        cancelPendingAnimations()
        resetAnimationState()

        schedule(after: 0.5) {
            withAnimation(.easeInOut(duration: 2.0)) {
                mountainOpacity = 1.0
                glowOpacity = 0.75
            }
        }

        schedule(after: 2.5) {
            withAnimation(.easeOut(duration: 0.7)) {
                logoOpacity = 1.0
                logoOffset = 0
            }
        }

        schedule(after: 2.9) {
            withAnimation(.easeInOut(duration: 0.4)) {
                wordmarkOpacity = 1.0
            }
        }

        schedule(after: 3.6) {
            withAnimation(.easeInOut(duration: 0.7)) {
                line1Opacity = 1.0
            }
        }

        schedule(after: 5.2) {
            withAnimation(.easeInOut(duration: 0.7)) {
                line2Opacity = 1.0
            }
        }

        schedule(after: 5.9) {
            withAnimation(.easeInOut(duration: 0.7)) {
                buttonOpacity = 1.0
            }
        }

        schedule(after: 6.6) {
            withAnimation(.easeInOut(duration: 4.0).repeatForever(autoreverses: true)) {
                glowPulse = true
            }
        }
    }

    private func resetAnimationState() {
        mountainOpacity = 0
        glowOpacity = 0
        logoOpacity = 0
        logoOffset = -6
        wordmarkOpacity = 0
        line1Opacity = 0
        line2Opacity = 0
        buttonOpacity = 0
        glowPulse = false
    }

    private func schedule(after delay: TimeInterval, action: @escaping () -> Void) {
        let item = DispatchWorkItem(block: action)
        pendingWorkItems.append(item)
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: item)
    }

    private func cancelPendingAnimations() {
        pendingWorkItems.forEach { $0.cancel() }
        pendingWorkItems.removeAll()
    }
}

// MARK: - Splash mountain (Canvas)

private struct OnboardingSplashMountain: View {
    var body: some View {
        GeometryReader { geo in
            Canvas { context, size in
                let scaleX = size.width / 320
                let scaleY = size.height / 280
                let scale = min(scaleX, scaleY)
                let offsetX = (size.width - 320 * scale) / 2
                let offsetY = (size.height - 280 * scale) / 2

                var ctx = context
                ctx.translateBy(x: offsetX, y: offsetY)
                ctx.scaleBy(x: scale, y: scale)

                let geom = SplashMountainGeometry()

                drawRidgeline(in: &ctx, path: geom.backLeftRidge, opacity: 0.4)
                drawRidgeline(in: &ctx, path: geom.backRightRidge, opacity: 0.4)

                for facet in geom.facets {
                    ctx.fill(facet.path, with: .color(facet.color))
                }
            }
        }
    }

    private func drawRidgeline(in context: inout GraphicsContext, path: Path, opacity: Double) {
        context.fill(path, with: .color(Color(hex: "#141414").opacity(opacity)))
    }
}

private struct SplashMountainFacet {
    let path: Path
    let color: Color
}

private struct SplashMountainGeometry {
    let facets: [SplashMountainFacet]
    let backLeftRidge: Path
    let backRightRidge: Path

    init() {
        backLeftRidge = Self.closed([
            CGPoint(x: 0, y: 250),
            CGPoint(x: 40, y: 190),
            CGPoint(x: 88, y: 150),
            CGPoint(x: 118, y: 128),
            CGPoint(x: 148, y: 250),
        ])

        backRightRidge = Self.closed([
            CGPoint(x: 172, y: 250),
            CGPoint(x: 198, y: 168),
            CGPoint(x: 232, y: 142),
            CGPoint(x: 268, y: 118),
            CGPoint(x: 320, y: 250),
        ])

        facets = [
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 148, y: 42),
                    CGPoint(x: 118, y: 88),
                    CGPoint(x: 92, y: 138),
                    CGPoint(x: 68, y: 182),
                    CGPoint(x: 34, y: 228),
                    CGPoint(x: 0, y: 250),
                    CGPoint(x: 148, y: 250),
                ]),
                color: Color(hex: "#111111"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 148, y: 42),
                    CGPoint(x: 128, y: 72),
                    CGPoint(x: 108, y: 118),
                    CGPoint(x: 148, y: 250),
                ]),
                color: Color(hex: "#151515"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 148, y: 42),
                    CGPoint(x: 168, y: 78),
                    CGPoint(x: 188, y: 122),
                    CGPoint(x: 218, y: 168),
                    CGPoint(x: 252, y: 210),
                    CGPoint(x: 320, y: 250),
                    CGPoint(x: 148, y: 250),
                ]),
                color: Color(hex: "#131313"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 148, y: 42),
                    CGPoint(x: 178, y: 96),
                    CGPoint(x: 148, y: 250),
                ]),
                color: Color(hex: "#1A1A1A"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 118, y: 88),
                    CGPoint(x: 148, y: 42),
                    CGPoint(x: 128, y: 72),
                ]),
                color: Color(hex: "#181818"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 168, y: 78),
                    CGPoint(x: 148, y: 42),
                    CGPoint(x: 178, y: 96),
                ]),
                color: Color(hex: "#161616"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 92, y: 138),
                    CGPoint(x: 118, y: 88),
                    CGPoint(x: 108, y: 118),
                    CGPoint(x: 148, y: 250),
                ]),
                color: Color(hex: "#121212"),
            ),
            SplashMountainFacet(
                path: Self.closed([
                    CGPoint(x: 188, y: 122),
                    CGPoint(x: 178, y: 96),
                    CGPoint(x: 198, y: 148),
                    CGPoint(x: 148, y: 250),
                ]),
                color: Color(hex: "#141414"),
            ),
        ]
    }

    private static func closed(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for point in points.dropFirst() {
            path.addLine(to: point)
        }
        path.closeSubpath()
        return path
    }
}
