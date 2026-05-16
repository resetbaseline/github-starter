import SwiftUI

/// Canvas mountain illustration driven by `completed` (stage = min(completed, 5)).
struct MountainProgressView: View {
    let completed: Int
    let total: Int

    private var stage: Int {
        min(max(completed, 0), 5)
    }

    var body: some View {
        Canvas { context, size in
            drawSky(context: context, size: size)
            drawStars(context: context, size: size)
            if stage == 5 {
                drawPeakRadialGlow(context: context, size: size)
            }
            switch stage {
            case 0:
                drawStage0(context: context, size: size)
            case 1:
                drawStage1(context: context, size: size)
            case 2:
                drawStage2(context: context, size: size)
            case 3:
                drawStage3(context: context, size: size)
            case 4:
                drawStage4(context: context, size: size)
            default:
                drawStage5(context: context, size: size)
            }
        }
        .frame(height: 100)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Mountain progress \(completed) of \(total) goals completed, stage \(stage) of five")
    }

    // MARK: - Shared sky + stars

    private func drawSky(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#0A0612"), Color(hex: "#0D0918")]),
                startPoint: CGPoint(x: 0, y: 0),
                endPoint: CGPoint(x: 0, y: size.height),
            ),
        )
    }

    private func drawStars(context: GraphicsContext, size: CGSize) {
        let stars: [(CGFloat, CGFloat, Double)] = [
            (0.08, 0.08, 0.35), (0.22, 0.18, 0.22), (0.38, 0.06, 0.40),
            (0.52, 0.14, 0.28), (0.68, 0.10, 0.34), (0.84, 0.07, 0.24),
            (0.15, 0.28, 0.32), (0.45, 0.24, 0.20), (0.72, 0.22, 0.38),
            (0.92, 0.20, 0.26),
        ]
        for (nx, ny, o) in stars {
            let p = CGPoint(x: nx * size.width, y: ny * size.height)
            var star = Path()
            star.addEllipse(in: CGRect(x: p.x - 0.8, y: p.y - 0.8, width: 1.6, height: 1.6))
            context.fill(star, with: .color(.white.opacity(o)))
        }
    }

    private func mountainFillShading(topY: CGFloat, bottomY: CGFloat, midX: CGFloat) -> GraphicsContext.Shading {
        .linearGradient(
            Gradient(stops: [
                .init(color: Color(hex: "#A882D8"), location: 0),
                .init(color: Color(hex: "#7C5CBF"), location: 0.2),
                .init(color: Color(hex: "#4A2878"), location: 0.5),
                .init(color: Color(hex: "#2A1548"), location: 0.8),
                .init(color: Color(hex: "#150A28"), location: 1),
            ]),
            startPoint: CGPoint(x: midX, y: topY),
            endPoint: CGPoint(x: midX, y: bottomY),
        )
    }

    private func drawPeakRadialGlow(context: GraphicsContext, size: CGSize) {
        let cx = size.width * 0.5
        let peakY = size.height * 0.04
        let r = CGRect(x: cx - 50, y: peakY - 10, width: 100, height: 90)
        var glow = Path()
        glow.addEllipse(in: r)
        context.fill(
            glow,
            with: .radialGradient(
                Gradient(colors: [
                    Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255).opacity(0.25),
                    Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255).opacity(0),
                ]),
                center: CGPoint(x: cx, y: peakY),
                startRadius: 0,
                endRadius: 40,
            ),
        )
    }

    // MARK: - Stage 0

    private func drawStage0(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - 6))
        path.addQuadCurve(to: CGPoint(x: w * 0.35, y: h - 14), control: CGPoint(x: w * 0.12, y: h - 22))
        path.addQuadCurve(to: CGPoint(x: w * 0.65, y: h - 12), control: CGPoint(x: w * 0.5, y: h - 20))
        path.addQuadCurve(to: CGPoint(x: w, y: h - 6), control: CGPoint(x: w * 0.88, y: h - 18))
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        context.fill(
            path,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#2A1548"), Color(hex: "#110828")]),
                startPoint: CGPoint(x: w * 0.5, y: h - 28),
                endPoint: CGPoint(x: w * 0.5, y: h),
            ),
        )
    }

    // MARK: - Stage 1

    private func drawStage1(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5
        let peakY = h * (1 - 0.42)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h - 4))
        path.addCurve(
            to: CGPoint(x: w, y: h - 4),
            control1: CGPoint(x: w * 0.25, y: peakY),
            control2: CGPoint(x: w * 0.75, y: peakY),
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        context.fill(path, with: mountainFillShading(topY: peakY, bottomY: h, midX: cx))
    }

    // MARK: - Stage 2

    private func drawStage2(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5
        let midPeakY = h * (1 - 0.62)
        let sidePeakY = h * (1 - 0.38)
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: sidePeakY + 18))
        path.addQuadCurve(
            to: CGPoint(x: w * 0.28, y: sidePeakY),
            control: CGPoint(x: w * 0.12, y: sidePeakY + 8),
        )
        path.addQuadCurve(
            to: CGPoint(x: cx, y: midPeakY),
            control: CGPoint(x: w * 0.38, y: midPeakY + 22),
        )
        path.addQuadCurve(
            to: CGPoint(x: w * 0.72, y: sidePeakY),
            control: CGPoint(x: w * 0.62, y: midPeakY + 22),
        )
        path.addQuadCurve(
            to: CGPoint(x: w, y: sidePeakY + 18),
            control: CGPoint(x: w * 0.88, y: sidePeakY + 8),
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        context.fill(path, with: mountainFillShading(topY: midPeakY, bottomY: h, midX: cx))
    }

    // MARK: - Back ridge (stages 3–5)

    private func backRidgePath(size: CGSize) -> Path {
        let w = size.width
        let h = size.height
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: h * 0.72))
        path.addCurve(
            to: CGPoint(x: w * 0.45, y: h * 0.58),
            control1: CGPoint(x: w * 0.15, y: h * 0.62),
            control2: CGPoint(x: w * 0.28, y: h * 0.52),
        )
        path.addCurve(
            to: CGPoint(x: w, y: h * 0.74),
            control1: CGPoint(x: w * 0.62, y: h * 0.52),
            control2: CGPoint(x: w * 0.82, y: h * 0.66),
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        return path
    }

    private func drawBackRidge(context: GraphicsContext, size: CGSize) {
        let p = backRidgePath(size: size)
        context.fill(
            p,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#1E0F40"), Color(hex: "#0D0820")]),
                startPoint: CGPoint(x: size.width * 0.5, y: size.height * 0.45),
                endPoint: CGPoint(x: size.width * 0.5, y: size.height),
            ),
        )
    }

    // MARK: - Matterhorn main shapes

    private func matterhornPath(size: CGSize, peakFactor: CGFloat) -> (path: Path, peak: CGPoint) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5
        let tipY = h * (1 - peakFactor)
        var path = Path()
        path.move(to: CGPoint(x: cx, y: tipY))
        path.addLine(to: CGPoint(x: cx - w * 0.06, y: tipY + h * 0.06))
        path.addLine(to: CGPoint(x: cx - w * 0.22, y: h * 0.50))
        path.addLine(to: CGPoint(x: cx - w * 0.38, y: h * 0.64))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: cx + w * 0.34, y: h * 0.64))
        path.addLine(to: CGPoint(x: cx + w * 0.14, y: h * 0.50))
        path.addLine(to: CGPoint(x: cx + w * 0.045, y: tipY + h * 0.055))
        path.closeSubpath()
        return (path, CGPoint(x: cx, y: tipY))
    }

    private func steppedMatterhornPath(size: CGSize, peakFactor: CGFloat) -> (path: Path, peak: CGPoint) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5
        let tipY = h * (1 - peakFactor)
        var path = Path()
        path.move(to: CGPoint(x: cx, y: tipY))
        path.addLine(to: CGPoint(x: cx - w * 0.04, y: tipY + h * 0.04))
        path.addLine(to: CGPoint(x: cx - w * 0.10, y: h * 0.36))
        path.addLine(to: CGPoint(x: cx - w * 0.20, y: h * 0.50))
        path.addLine(to: CGPoint(x: cx - w * 0.30, y: h * 0.58))
        path.addLine(to: CGPoint(x: cx - w * 0.42, y: h * 0.66))
        path.addLine(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: w, y: h))
        path.addLine(to: CGPoint(x: cx + w * 0.40, y: h * 0.66))
        path.addLine(to: CGPoint(x: cx + w * 0.26, y: h * 0.58))
        path.addLine(to: CGPoint(x: cx + w * 0.14, y: h * 0.50))
        path.addLine(to: CGPoint(x: cx + w * 0.06, y: h * 0.36))
        path.addLine(to: CGPoint(x: cx + w * 0.025, y: tipY + h * 0.038))
        path.closeSubpath()
        return (path, CGPoint(x: cx, y: tipY))
    }

    private func snowCapPath(peak: CGPoint, halfWidth: CGFloat) -> Path {
        var path = Path()
        path.move(to: peak)
        path.addLine(to: CGPoint(x: peak.x - halfWidth, y: peak.y + 16))
        path.addLine(to: CGPoint(x: peak.x + halfWidth * 0.85, y: peak.y + 16))
        path.closeSubpath()
        return path
    }

    private func drawRidgeHighlights(context: GraphicsContext, peak: CGPoint, size: CGSize, w: CGFloat) {
        let h = size.height
        var left = Path()
        left.move(to: peak)
        left.addLine(to: CGPoint(x: peak.x - w * 0.18, y: h * 0.52))
        var right = Path()
        right.move(to: peak)
        right.addLine(to: CGPoint(x: peak.x + w * 0.14, y: h * 0.52))
        let hi = Color(red: 180 / 255, green: 140 / 255, blue: 255 / 255).opacity(0.5)
        context.stroke(left, with: .color(hi), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
        context.stroke(right, with: .color(hi), style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round))
    }

    private func drawSnowAndPeak(context: GraphicsContext, peak: CGPoint, capHalfWidth: CGFloat) {
        let snow = snowCapPath(peak: peak, halfWidth: capHalfWidth)
        context.fill(
            snow,
            with: .linearGradient(
                Gradient(colors: [.white, .white.opacity(0)]),
                startPoint: peak,
                endPoint: CGPoint(x: peak.x, y: peak.y + 18),
            ),
        )
        var dot = Path()
        dot.addEllipse(in: CGRect(x: peak.x - 2.5, y: peak.y - 2.5, width: 5, height: 5))
        context.fill(dot, with: .color(.white))
    }

    private func drawStage3(context: GraphicsContext, size: CGSize) {
        drawBackRidge(context: context, size: size)
        let (mp, peak) = matterhornPath(size: size, peakFactor: 0.82)
        context.fill(mp, with: mountainFillShading(topY: peak.y, bottomY: size.height, midX: peak.x))
        drawRidgeHighlights(context: context, peak: peak, size: size, w: size.width)
        drawSnowAndPeak(context: context, peak: peak, capHalfWidth: 10)
    }

    private func drawStage4(context: GraphicsContext, size: CGSize) {
        drawBackRidge(context: context, size: size)
        let (mp, peak) = matterhornPath(size: size, peakFactor: 0.92)
        context.fill(mp, with: mountainFillShading(topY: peak.y, bottomY: size.height, midX: peak.x))
        drawRidgeHighlights(context: context, peak: peak, size: size, w: size.width)
        var left2 = Path()
        left2.move(to: CGPoint(x: peak.x - 4, y: peak.y + 8))
        left2.addLine(to: CGPoint(x: peak.x - size.width * 0.22, y: size.height * 0.48))
        var right2 = Path()
        right2.move(to: CGPoint(x: peak.x + 3, y: peak.y + 8))
        right2.addLine(to: CGPoint(x: peak.x + size.width * 0.18, y: size.height * 0.48))
        let hi = Color(red: 180 / 255, green: 140 / 255, blue: 255 / 255).opacity(0.5)
        context.stroke(left2, with: .color(hi), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        context.stroke(right2, with: .color(hi), style: StrokeStyle(lineWidth: 1.4, lineCap: .round))
        drawSnowAndPeak(context: context, peak: peak, capHalfWidth: 14)
    }

    private func drawStage5(context: GraphicsContext, size: CGSize) {
        drawBackRidge(context: context, size: size)
        let (mp, peak) = steppedMatterhornPath(size: size, peakFactor: 0.96)
        context.fill(mp, with: mountainFillShading(topY: peak.y, bottomY: size.height, midX: peak.x))
        drawRidgeHighlights(context: context, peak: peak, size: size, w: size.width)
        var left2 = Path()
        left2.move(to: CGPoint(x: peak.x - 2, y: peak.y + 6))
        left2.addLine(to: CGPoint(x: peak.x - size.width * 0.24, y: size.height * 0.46))
        var right2 = Path()
        right2.move(to: CGPoint(x: peak.x + 2, y: peak.y + 6))
        right2.addLine(to: CGPoint(x: peak.x + size.width * 0.20, y: size.height * 0.46))
        let hi = Color(red: 180 / 255, green: 140 / 255, blue: 255 / 255).opacity(0.55)
        context.stroke(left2, with: .color(hi), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        context.stroke(right2, with: .color(hi), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
        drawSnowAndPeak(context: context, peak: peak, capHalfWidth: 18)
    }
}
