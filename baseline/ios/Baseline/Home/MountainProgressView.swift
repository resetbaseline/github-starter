import SwiftUI

/// SwiftUI `Canvas` mountain driven by `completed` (`stage = min(completed, 5)`).
struct MountainProgressView: View {
    let completed: Int
    let total: Int

    private var stage: Int {
        min(max(completed, 0), 5)
    }

    var body: some View {
        Canvas { context, size in
            drawSky(context: context, size: size)
            drawNebula(context: context, size: size)
            drawStars(context: context, size: size)

            switch stage {
            case 0:
                drawStage0(context: context, size: size)
            case 1:
                drawStage1(context: context, size: size)
            case 2:
                drawStage2(context: context, size: size)
            case 3:
                drawMatterhornStages(context: context, size: size, matterhornStage: 3)
            case 4:
                drawMatterhornStages(context: context, size: size, matterhornStage: 4)
            default:
                drawMatterhornStages(context: context, size: size, matterhornStage: 5)
            }
        }
        .frame(height: 70)
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Mountain progress \(completed) of \(total) goals completed, stage \(stage) of five")
    }

    // MARK: - Shared sky, nebula, stars

    private func drawSky(context: GraphicsContext, size: CGSize) {
        let rect = CGRect(origin: .zero, size: size)
        context.fill(
            Path(rect),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(hex: "#04020C"), location: 0),
                    .init(color: Color(hex: "#080514"), location: 0.4),
                    .init(color: Color(hex: "#120830"), location: 1),
                ]),
                startPoint: .zero,
                endPoint: CGPoint(x: 0, y: size.height),
            ),
        )
    }

    private func drawNebula(context: GraphicsContext, size: CGSize) {
        let cx = size.width * 0.5
        let cy = size.height * 0.1
        let r = size.width * 0.5
        var oval = Path()
        oval.addEllipse(in: CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2))
        context.fill(
            oval,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(red: 80 / 255, green: 40 / 255, blue: 140 / 255, opacity: 0.12), location: 0),
                    .init(color: Color(red: 60 / 255, green: 20 / 255, blue: 100 / 255, opacity: 0.06), location: 0.45),
                    .init(color: Color.clear, location: 1),
                ]),
                center: CGPoint(x: cx, y: cy),
                startRadius: 0,
                endRadius: r,
            ),
        )
    }

    private func drawStars(context: GraphicsContext, size: CGSize) {
        let stars: [(CGFloat, CGFloat, Double, CGFloat)] = [
            (0.06, 0.06, 0.5, 1.0), (0.15, 0.18, 0.35, 0.7), (0.28, 0.05, 0.55, 1.0),
            (0.42, 0.14, 0.4, 0.8), (0.58, 0.04, 0.5, 1.0), (0.7, 0.16, 0.3, 0.7),
            (0.82, 0.07, 0.48, 1.0), (0.91, 0.2, 0.38, 0.8), (0.22, 0.28, 0.28, 0.6),
            (0.75, 0.24, 0.35, 0.7), (0.5, 0.22, 0.25, 0.6),
        ]
        for (nx, ny, opacity, radius) in stars {
            let p = CGPoint(x: nx * size.width, y: ny * size.height)
            var star = Path()
            star.addEllipse(in: CGRect(x: p.x - radius, y: p.y - radius, width: radius * 2, height: radius * 2))
            context.fill(star, with: .color(.white.opacity(opacity)))
            if opacity > 0.45 {
                let crossOpacity = opacity * 0.4
                let arm: CGFloat = 2
                var hLine = Path()
                hLine.move(to: CGPoint(x: p.x - arm, y: p.y))
                hLine.addLine(to: CGPoint(x: p.x + arm, y: p.y))
                var vLine = Path()
                vLine.move(to: CGPoint(x: p.x, y: p.y - arm))
                vLine.addLine(to: CGPoint(x: p.x, y: p.y + arm))
                let c = Color.white.opacity(crossOpacity)
                context.stroke(hLine, with: .color(c), style: StrokeStyle(lineWidth: 0.5, lineCap: .round))
                context.stroke(vLine, with: .color(c), style: StrokeStyle(lineWidth: 0.5, lineCap: .round))
            }
        }
    }

    // MARK: - Stage 0

    private func drawStage0(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let y0 = h * 0.55
        var base = Path()
        base.move(to: CGPoint(x: 0, y: h))
        base.addLine(to: CGPoint(x: 0, y: y0 + 8))
        base.addQuadCurve(
            to: CGPoint(x: w, y: y0 + 6),
            control: CGPoint(x: w * 0.5, y: y0 - 6),
        )
        base.addLine(to: CGPoint(x: w, y: h))
        base.closeSubpath()
        context.fill(
            base,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#180B30"), Color(hex: "#0A0520")]),
                startPoint: CGPoint(x: w * 0.5, y: y0 - 10),
                endPoint: CGPoint(x: w * 0.5, y: h),
            ),
        )
        let bandY = h * 0.68
        let band = CGRect(x: 0, y: bandY - 4, width: w, height: 8)
        context.fill(
            Path(band),
            with: .linearGradient(
                Gradient(colors: [
                    Color(red: 100 / 255, green: 60 / 255, blue: 180 / 255, opacity: 0.3),
                    Color.clear,
                ]),
                startPoint: CGPoint(x: w * 0.5, y: bandY - 4),
                endPoint: CGPoint(x: w * 0.5, y: bandY + 4),
            ),
        )
    }

    // MARK: - Stage 1

    private func drawStage1(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let peakY = h * 0.2
        var hill = Path()
        hill.move(to: CGPoint(x: 0, y: h))
        hill.addLine(to: CGPoint(x: 0, y: h * 0.78))
        hill.addCurve(
            to: CGPoint(x: w, y: h * 0.78),
            control1: CGPoint(x: w * 0.28, y: peakY),
            control2: CGPoint(x: w * 0.72, y: peakY),
        )
        hill.addLine(to: CGPoint(x: w, y: h))
        hill.closeSubpath()
        context.fill(
            hill,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#160830"), Color(hex: "#0A0520")]),
                startPoint: CGPoint(x: w * 0.5, y: peakY),
                endPoint: CGPoint(x: w * 0.5, y: h),
            ),
        )
        var rim = Path()
        rim.move(to: CGPoint(x: 0, y: h * 0.78))
        rim.addCurve(
            to: CGPoint(x: w, y: h * 0.78),
            control1: CGPoint(x: w * 0.28, y: peakY),
            control2: CGPoint(x: w * 0.72, y: peakY),
        )
        context.stroke(
            rim,
            with: .color(Color(red: 120 / 255, green: 80 / 255, blue: 200 / 255, opacity: 0.25)),
            style: StrokeStyle(lineWidth: 1, lineCap: .round),
        )
    }

    // MARK: - Stage 2

    private func drawStage2(context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5
        let bgPeakY = h * 0.34
        var back = Path()
        back.move(to: CGPoint(x: 0, y: h))
        back.addLine(to: CGPoint(x: 0, y: h * 0.72))
        back.addCurve(
            to: CGPoint(x: cx, y: bgPeakY + 14),
            control1: CGPoint(x: w * 0.22, y: h * 0.58),
            control2: CGPoint(x: w * 0.38, y: bgPeakY + 20),
        )
        back.addCurve(
            to: CGPoint(x: w, y: h * 0.72),
            control1: CGPoint(x: w * 0.62, y: bgPeakY + 20),
            control2: CGPoint(x: w * 0.78, y: h * 0.58),
        )
        back.addLine(to: CGPoint(x: w, y: h))
        back.closeSubpath()
        context.fill(
            back,
            with: .linearGradient(
                Gradient(colors: [Color(hex: "#1A0A35"), Color(hex: "#0D0622")]),
                startPoint: CGPoint(x: cx, y: bgPeakY),
                endPoint: CGPoint(x: cx, y: h),
            ),
        )
        let fgPeakY = h * 0.26
        var front = Path()
        front.move(to: CGPoint(x: 0, y: h))
        front.addLine(to: CGPoint(x: 0, y: h * 0.76))
        front.addCurve(
            to: CGPoint(x: cx, y: fgPeakY + 10),
            control1: CGPoint(x: w * 0.24, y: h * 0.52),
            control2: CGPoint(x: w * 0.4, y: fgPeakY + 16),
        )
        front.addCurve(
            to: CGPoint(x: w, y: h * 0.76),
            control1: CGPoint(x: w * 0.6, y: fgPeakY + 16),
            control2: CGPoint(x: w * 0.76, y: h * 0.52),
        )
        front.addLine(to: CGPoint(x: w, y: h))
        front.closeSubpath()
        context.fill(
            front,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(hex: "#8B6ACC"), location: 0),
                    .init(color: Color(hex: "#5A3A90"), location: 0.5),
                    .init(color: Color(hex: "#1A0A35"), location: 1),
                ]),
                startPoint: CGPoint(x: cx, y: fgPeakY),
                endPoint: CGPoint(x: cx, y: h),
            ),
        )
    }

    // MARK: - Stages 3–5 Matterhorn

    private func drawMatterhornStages(context: GraphicsContext, size: CGSize, matterhornStage: Int) {
        let w = size.width
        let h = size.height
        let cx = w * 0.5

        drawBackgroundRidge(context: context, w: w, h: h, topFactor: 0.82, fill: Color(hex: "#0E0520"))
        drawBackgroundRidge(context: context, w: w, h: h, topFactor: 0.72, fill: Color(hex: "#130828"))
        drawBackgroundRidge(context: context, w: w, h: h, topFactor: 0.62, fill: Color(hex: "#180B30"))

        let mistRect = CGRect(x: 0, y: h * 0.4, width: w, height: h * 0.6)
        context.fill(
            Path(mistRect),
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(red: 60 / 255, green: 20 / 255, blue: 100 / 255, opacity: 0), location: 0),
                    .init(color: Color(red: 40 / 255, green: 10 / 255, blue: 80 / 255, opacity: 0.15), location: 0.5),
                    .init(color: Color(red: 20 / 255, green: 5 / 255, blue: 50 / 255, opacity: 0.4), location: 1),
                ]),
                startPoint: CGPoint(x: cx, y: h * 0.4),
                endPoint: CGPoint(x: cx, y: h),
            ),
        )

        let tipY: CGFloat = {
            switch matterhornStage {
            case 3: return h * 0.06
            case 4: return h * 0.02
            default: return h * (-0.01)
            }
        }()

        if matterhornStage == 4 {
            drawTipGlowLarge(
                context: context,
                center: CGPoint(x: cx, y: tipY),
                inner: Color(red: 140 / 255, green: 100 / 255, blue: 210 / 255, opacity: 0.2),
                mid: Color(red: 100 / 255, green: 60 / 255, blue: 180 / 255, opacity: 0.08),
                radius: 45,
            )
        }
        if matterhornStage == 5 {
            drawTipGlowLarge(
                context: context,
                center: CGPoint(x: cx, y: tipY),
                inner: Color(red: 140 / 255, green: 100 / 255, blue: 210 / 255, opacity: 0.28),
                mid: Color(red: 100 / 255, green: 60 / 255, blue: 180 / 255, opacity: 0.14),
                radius: 60,
            )
            drawAurora(context: context, w: w, h: h, cx: cx)
        }

        let leftPts = leftFacePoints(cx: cx, h: h, tipY: tipY, stage: matterhornStage)
        let rightPts = rightFacePoints(cx: cx, w: w, h: h, tipY: tipY, stage: matterhornStage)

        fillFace(
            context: context,
            points: leftPts,
            start: CGPoint(x: cx - 60, y: tipY),
            end: CGPoint(x: cx, y: h),
            stops: [
                (Color(hex: "#9B7FD4"), 0),
                (Color(hex: "#6B45A8"), 0.15),
                (Color(hex: "#3D2068"), 0.4),
                (Color(hex: "#20103A"), 0.75),
                (Color(hex: "#120828"), 1),
            ],
        )
        fillFace(
            context: context,
            points: rightPts,
            start: CGPoint(x: cx, y: tipY),
            end: CGPoint(x: cx + 60, y: h),
            stops: [
                (Color(hex: "#B090E0"), 0),
                (Color(hex: "#7C5CBF"), 0.15),
                (Color(hex: "#4A2878"), 0.4),
                (Color(hex: "#251248"), 0.75),
                (Color(hex: "#150830"), 1),
            ],
        )

        drawRightShadow(context: context, cx: cx, tipY: tipY, w: w, h: h)

        let snowHalf: CGFloat = matterhornStage == 3 ? 11 : (matterhornStage == 4 ? 14 : 17)
        drawSnowCap(context: context, cx: cx, tipY: tipY, h: h, halfWidth: snowHalf)

        let tip = CGPoint(x: cx, y: tipY)
        let leftFirst = leftPts[1]
        let rightFirst = rightPts[1]
        var hl = Path()
        hl.move(to: tip)
        hl.addLine(to: leftFirst)
        var hr = Path()
        hr.move(to: tip)
        hr.addLine(to: rightFirst)
        let ridgeHi = Color(red: 200 / 255, green: 165 / 255, blue: 255 / 255, opacity: 0.45)
        context.stroke(hl, with: .color(ridgeHi), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))
        context.stroke(hr, with: .color(ridgeHi), style: StrokeStyle(lineWidth: 1.1, lineCap: .round))

        var spine = Path()
        spine.move(to: CGPoint(x: cx, y: tipY + 2))
        spine.addLine(to: CGPoint(x: cx + 2, y: h * 0.35))
        context.stroke(
            spine,
            with: .color(Color(red: 210 / 255, green: 180 / 255, blue: 255 / 255, opacity: 0.18)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round),
        )

        let glowCenter = CGPoint(x: cx, y: tipY - 1)
        var tipGlow = Path()
        tipGlow.addEllipse(in: CGRect(x: glowCenter.x - 6, y: glowCenter.y - 6, width: 12, height: 12))
        context.fill(
            tipGlow,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: .white, location: 0),
                    .init(color: Color(red: 230 / 255, green: 220 / 255, blue: 255 / 255, opacity: 0.8), location: 0.5),
                    .init(color: .clear, location: 1),
                ]),
                center: glowCenter,
                startRadius: 0,
                endRadius: 5,
            ),
        )

        var dot = Path()
        dot.addEllipse(in: CGRect(x: cx - 2, y: tipY - 2, width: 4, height: 4))
        context.fill(dot, with: .color(.white))
    }

    private func drawBackgroundRidge(context: GraphicsContext, w: CGFloat, h: CGFloat, topFactor: CGFloat, fill: Color) {
        let yEdge = h * topFactor
        let dip: CGFloat = 10
        var path = Path()
        path.move(to: CGPoint(x: 0, y: h))
        path.addLine(to: CGPoint(x: 0, y: yEdge))
        path.addCurve(
            to: CGPoint(x: w, y: yEdge),
            control1: CGPoint(x: w * 0.35, y: yEdge + dip),
            control2: CGPoint(x: w * 0.65, y: yEdge + dip),
        )
        path.addLine(to: CGPoint(x: w, y: h))
        path.closeSubpath()
        context.fill(path, with: .color(fill))
    }

    private func leftFacePoints(cx: CGFloat, h: CGFloat, tipY: CGFloat, stage: Int) -> [CGPoint] {
        switch stage {
        case 3:
            return [
                CGPoint(x: cx, y: tipY),
                CGPoint(x: cx - 7, y: tipY + h * 0.08),
                CGPoint(x: cx - 20, y: h * 0.3),
                CGPoint(x: cx - 40, y: h * 0.52),
                CGPoint(x: cx - 72, y: h * 0.76),
                CGPoint(x: 0, y: h),
                CGPoint(x: cx, y: h),
            ]
        case 4:
            return [
                CGPoint(x: cx, y: tipY),
                CGPoint(x: cx - 6, y: tipY + h * 0.06),
                CGPoint(x: cx - 16, y: h * 0.24),
                CGPoint(x: cx - 34, y: h * 0.44),
                CGPoint(x: cx - 56, y: h * 0.62),
                CGPoint(x: cx - 82, y: h * 0.8),
                CGPoint(x: 0, y: h),
                CGPoint(x: cx, y: h),
            ]
        default:
            return [
                CGPoint(x: cx, y: tipY),
                CGPoint(x: cx - 5, y: tipY + h * 0.05),
                CGPoint(x: cx - 13, y: h * 0.2),
                CGPoint(x: cx - 28, y: h * 0.36),
                CGPoint(x: cx - 44, y: h * 0.52),
                CGPoint(x: cx - 64, y: h * 0.66),
                CGPoint(x: cx - 92, y: h * 0.84),
                CGPoint(x: 0, y: h),
                CGPoint(x: cx, y: h),
            ]
        }
    }

    private func rightFacePoints(cx: CGFloat, w: CGFloat, h: CGFloat, tipY: CGFloat, stage: Int) -> [CGPoint] {
        switch stage {
        case 3:
            return [
                CGPoint(x: cx, y: tipY),
                CGPoint(x: cx + 7, y: tipY + h * 0.08),
                CGPoint(x: cx + 20, y: h * 0.3),
                CGPoint(x: cx + 40, y: h * 0.52),
                CGPoint(x: cx + 72, y: h * 0.76),
                CGPoint(x: w, y: h),
                CGPoint(x: cx, y: h),
            ]
        case 4:
            return [
                CGPoint(x: cx, y: tipY),
                CGPoint(x: cx + 6, y: tipY + h * 0.06),
                CGPoint(x: cx + 16, y: h * 0.24),
                CGPoint(x: cx + 34, y: h * 0.44),
                CGPoint(x: cx + 56, y: h * 0.62),
                CGPoint(x: cx + 82, y: h * 0.8),
                CGPoint(x: w, y: h),
                CGPoint(x: cx, y: h),
            ]
        default:
            return [
                CGPoint(x: cx, y: tipY),
                CGPoint(x: cx + 5, y: tipY + h * 0.05),
                CGPoint(x: cx + 13, y: h * 0.2),
                CGPoint(x: cx + 28, y: h * 0.36),
                CGPoint(x: cx + 44, y: h * 0.52),
                CGPoint(x: cx + 64, y: h * 0.66),
                CGPoint(x: cx + 92, y: h * 0.84),
                CGPoint(x: w, y: h),
                CGPoint(x: cx, y: h),
            ]
        }
    }

    private func fillFace(
        context: GraphicsContext,
        points: [CGPoint],
        start: CGPoint,
        end: CGPoint,
        stops: [(Color, CGFloat)],
    ) {
        var path = Path()
        guard let first = points.first else { return }
        path.move(to: first)
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        path.closeSubpath()
        let gradient = Gradient(stops: stops.map { Gradient.Stop(color: $0.0, location: $0.1) })
        context.fill(path, with: .linearGradient(gradient, startPoint: start, endPoint: end))
    }

    private func drawRightShadow(context: GraphicsContext, cx: CGFloat, tipY: CGFloat, w: CGFloat, h: CGFloat) {
        var tri = Path()
        tri.move(to: CGPoint(x: cx + 4, y: tipY + h * 0.04))
        tri.addLine(to: CGPoint(x: w * 0.92, y: h * 0.58))
        tri.addLine(to: CGPoint(x: cx + 28, y: h * 0.52))
        tri.closeSubpath()
        context.fill(tri, with: .color(Color(red: 140 / 255, green: 100 / 255, blue: 200 / 255, opacity: 0.3)))
    }

    private func drawSnowCap(context: GraphicsContext, cx: CGFloat, tipY: CGFloat, h: CGFloat, halfWidth: CGFloat) {
        let tip = CGPoint(x: cx, y: tipY)
        let p1 = CGPoint(x: cx - halfWidth * 0.25, y: tipY + h * 0.04)
        let p2 = CGPoint(x: cx - halfWidth, y: tipY + h * 0.10)
        let p3 = CGPoint(x: cx - halfWidth * 0.65, y: tipY + h * 0.15)
        let p4 = CGPoint(x: cx + halfWidth * 0.6, y: tipY + h * 0.15)
        let p5 = CGPoint(x: cx + halfWidth * 0.22, y: tipY + h * 0.045)
        var poly = Path()
        poly.move(to: tip)
        poly.addLine(to: p1)
        poly.addLine(to: p2)
        poly.addLine(to: p3)
        poly.addLine(to: p4)
        poly.addLine(to: p5)
        poly.closeSubpath()
        context.fill(
            poly,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(red: 235 / 255, green: 225 / 255, blue: 255 / 255, opacity: 0.95), location: 0),
                    .init(color: Color.white, location: 0.3),
                    .init(color: Color(red: 220 / 255, green: 210 / 255, blue: 245 / 255, opacity: 0.85), location: 0.7),
                    .init(color: Color(red: 150 / 255, green: 120 / 255, blue: 210 / 255, opacity: 0), location: 1),
                ]),
                startPoint: tip,
                endPoint: CGPoint(x: cx, y: tipY + h * 0.16),
            ),
        )
    }

    private func drawTipGlowLarge(
        context: GraphicsContext,
        center: CGPoint,
        inner: Color,
        mid: Color,
        radius: CGFloat,
    ) {
        var oval = Path()
        oval.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2))
        context.fill(
            oval,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: inner, location: 0),
                    .init(color: mid, location: 0.45),
                    .init(color: .clear, location: 1),
                ]),
                center: center,
                startRadius: 0,
                endRadius: radius,
            ),
        )
    }

    private func drawAurora(context: GraphicsContext, w: CGFloat, h: CGFloat, cx: CGFloat) {
        var w1 = Path()
        w1.move(to: CGPoint(x: cx - 40, y: h * 0.3))
        w1.addCurve(
            to: CGPoint(x: cx + 50, y: h * 0.28),
            control1: CGPoint(x: cx - 20, y: h * 0.15),
            control2: CGPoint(x: cx + 10, y: h * 0.22),
        )
        context.stroke(
            w1,
            with: .color(Color(red: 140 / 255, green: 90 / 255, blue: 220 / 255, opacity: 0.2)),
            style: StrokeStyle(lineWidth: 2, lineCap: .round),
        )
        var w2 = Path()
        w2.move(to: CGPoint(x: cx - 55, y: h * 0.4))
        w2.addCurve(
            to: CGPoint(x: cx + 60, y: h * 0.38),
            control1: CGPoint(x: cx - 25, y: h * 0.22),
            control2: CGPoint(x: cx + 15, y: h * 0.3),
        )
        context.stroke(
            w2,
            with: .color(Color(red: 120 / 255, green: 70 / 255, blue: 200 / 255, opacity: 0.12)),
            style: StrokeStyle(lineWidth: 1.5, lineCap: .round),
        )
    }
}
