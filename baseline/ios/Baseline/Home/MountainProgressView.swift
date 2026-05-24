import SwiftUI

/// Matterhorn-style progress mountain — fixed geometry, progress-driven lighting only.
struct MountainProgressView: View {
    let completed: Int
    let total: Int

    private var safeTotal: Int { max(total, 0) }
    private var safeCompleted: Int { min(max(completed, 0), safeTotal) }

    private var progress: Double {
        guard safeTotal > 0 else { return 0 }
        return Double(safeCompleted) / Double(safeTotal)
    }

    var body: some View {
        Canvas { context, size in
            let scaleX = size.width / 234
            let scaleY = size.height / 140
            let scale = min(scaleX, scaleY)
            let offsetX = (size.width - 234 * scale) / 2
            let offsetY = (size.height - 140 * scale) / 2

            var ctx = context
            ctx.translateBy(x: offsetX, y: offsetY)
            ctx.scaleBy(x: scale, y: scale)

            let geom = MountainGeometry()
            let emerge = 0.15 + progress * 0.85
            let facetAlpha = 0.08 + progress * 0.92
            let ridgeGlow = 0.12 + progress * 0.88
            let snowAlpha = progress > 0.7 ? min(1, (progress - 0.7) / 0.3) : 0

            drawBackground(in: &ctx)
            drawAtmosphericGlow(in: &ctx, geom: geom, intensity: ridgeGlow)
            drawMountainBody(in: &ctx, geom: geom, emerge: emerge)
            drawFacets(in: &ctx, geom: geom, alpha: facetAlpha)
            if snowAlpha > 0 {
                drawSnowCap(in: &ctx, geom: geom, alpha: snowAlpha)
            }
            drawRightRidge(in: &ctx, geom: geom, intensity: 0.15 + progress * 0.35)
            drawLeftRidgeGlow(in: &ctx, geom: geom, intensity: ridgeGlow)
            drawAscentPath(in: &ctx, geom: geom, progress: progress)
            drawNodes(in: &ctx, geom: geom, completed: safeCompleted, total: safeTotal)
            drawSummit(in: &ctx, geom: geom, showStar: progress >= 1 && safeTotal > 0)
        }
        .frame(width: 234, height: 140)
        .accessibilityLabel("Mountain progress \(safeCompleted) of \(safeTotal) goals completed")
    }

    // MARK: - Background

    private func drawBackground(in context: inout GraphicsContext) {
        context.fill(
            Path(CGRect(x: 0, y: 0, width: 234, height: 140)),
            with: .color(Color(hex: "#0D0D0D")),
        )
    }

    private func drawAtmosphericGlow(in context: inout GraphicsContext, geom: MountainGeometry, intensity: Double) {
        let center = geom.apex
        let radius: CGFloat = 58
        var oval = Path()
        oval.addEllipse(in: CGRect(x: center.x - radius, y: center.y - radius * 0.6, width: radius * 2, height: radius * 1.2))
        context.fill(
            oval,
            with: .radialGradient(
                Gradient(stops: [
                    .init(color: Color(hex: "#7C5CBF").opacity(intensity * 0.35), location: 0),
                    .init(color: Color(hex: "#5A3A90").opacity(intensity * 0.12), location: 0.45),
                    .init(color: Color.clear, location: 1),
                ]),
                center: center,
                startRadius: 0,
                endRadius: radius,
            ),
        )
    }

    // MARK: - Body

    private func drawMountainBody(in context: inout GraphicsContext, geom: MountainGeometry, emerge: Double) {
        context.fill(geom.rightFace, with: .color(Color(hex: "#0A0812").opacity(emerge)))
        context.fill(geom.leftFace, with: .color(Color(hex: "#080610").opacity(emerge)))
        context.fill(geom.centralFace, with: .color(Color(hex: "#0C0A14").opacity(emerge * 0.95)))
    }

    private func drawFacets(in context: inout GraphicsContext, geom: MountainGeometry, alpha: Double) {
        let lineColor = Color(hex: "#2A1848").opacity(alpha * 0.55)
        let accentLine = Color(hex: "#5A3A90").opacity(alpha * 0.35)
        let style = StrokeStyle(lineWidth: 0.6, lineCap: .round, lineJoin: .round)

        for path in geom.leftFacetLines {
            context.stroke(path, with: .color(lineColor), style: style)
        }
        for path in geom.rightFacetLines {
            context.stroke(path, with: .color(lineColor.opacity(0.7)), style: style)
        }
        context.stroke(geom.leftRidgeLine, with: .color(accentLine), style: StrokeStyle(lineWidth: 0.8, lineCap: .round))
    }

    private func drawSnowCap(in context: inout GraphicsContext, geom: MountainGeometry, alpha: Double) {
        context.fill(
            geom.snowCap,
            with: .linearGradient(
                Gradient(stops: [
                    .init(color: Color(hex: "#EDE8FA").opacity(alpha * 0.95), location: 0),
                    .init(color: Color(hex: "#C4A0FF").opacity(alpha * 0.55), location: 0.55),
                    .init(color: Color(hex: "#7C5CBF").opacity(0), location: 1),
                ]),
                startPoint: geom.apex,
                endPoint: CGPoint(x: geom.apex.x, y: geom.apex.y + 22),
            ),
        )
    }

    // MARK: - Ridges

    private func drawRightRidge(in context: inout GraphicsContext, geom: MountainGeometry, intensity: Double) {
        context.stroke(
            geom.rightRidgeLine,
            with: .color(Color(hex: "#7C5CBF").opacity(intensity)),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round),
        )
    }

    private func drawLeftRidgeGlow(in context: inout GraphicsContext, geom: MountainGeometry, intensity: Double) {
        let color = Color(hex: "#7C5CBF").opacity(intensity)

        var bloom = context
        bloom.addFilter(.blur(radius: 6))
        bloom.stroke(
            geom.leftRidgeLine,
            with: .color(color.opacity(0.55)),
            style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round),
        )

        var mid = context
        mid.addFilter(.blur(radius: 2.5))
        mid.stroke(
            geom.leftRidgeLine,
            with: .color(color.opacity(0.75)),
            style: StrokeStyle(lineWidth: 2.8, lineCap: .round, lineJoin: .round),
        )

        context.stroke(
            geom.leftRidgeLine,
            with: .color(Color(hex: "#C4A0FF").opacity(intensity)),
            style: StrokeStyle(lineWidth: 1.4, lineCap: .round, lineJoin: .round),
        )
    }

    // MARK: - Path & nodes

    private func drawAscentPath(in context: inout GraphicsContext, geom: MountainGeometry, progress: Double) {
        let dimStyle = StrokeStyle(lineWidth: 1, lineCap: .round, lineJoin: .round, dash: [3, 3])
        context.stroke(
            geom.ascentPath,
            with: .color(Color(hex: "#3A2060").opacity(0.35)),
            style: dimStyle,
        )

        guard progress > 0 else { return }

        let trimmed = geom.trimmedAscentPath(fraction: progress)
        context.stroke(
            trimmed,
            with: .color(Color(hex: "#9B7FD4").opacity(0.55 + progress * 0.45)),
            style: StrokeStyle(lineWidth: 1.2, lineCap: .round, lineJoin: .round),
        )

        var glow = context
        glow.addFilter(.blur(radius: 2))
        glow.stroke(
            trimmed,
            with: .color(Color(hex: "#7C5CBF").opacity(0.35 * progress)),
            style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round),
        )
    }

    private func drawNodes(in context: inout GraphicsContext, geom: MountainGeometry, completed: Int, total: Int) {
        guard total > 0 else { return }

        let points = geom.nodePoints(count: total)
        for (index, point) in points.enumerated() {
            if index < completed {
                drawCompletedNode(in: &context, at: point)
            } else if index == completed && completed < total {
                drawCurrentNode(in: &context, at: point)
            } else {
                drawIncompleteNode(in: &context, at: point)
            }
        }
    }

    private func drawCompletedNode(in context: inout GraphicsContext, at point: CGPoint) {
        let outer: CGFloat = 5.5
        var ring = Path()
        ring.addEllipse(in: CGRect(x: point.x - outer, y: point.y - outer, width: outer * 2, height: outer * 2))
        context.fill(ring, with: .color(Color(hex: "#7C5CBF")))

        var glow = context
        glow.addFilter(.blur(radius: 2))
        glow.stroke(ring, with: .color(Color(hex: "#7C5CBF").opacity(0.5)), style: StrokeStyle(lineWidth: 2))

        let inner: CGFloat = 1.8
        var dot = Path()
        dot.addEllipse(in: CGRect(x: point.x - inner, y: point.y - inner, width: inner * 2, height: inner * 2))
        context.fill(dot, with: .color(Color(hex: "#EDE8FA")))
    }

    private func drawCurrentNode(in context: inout GraphicsContext, at point: CGPoint) {
        let outer: CGFloat = 5.5
        var ring = Path()
        ring.addEllipse(in: CGRect(x: point.x - outer, y: point.y - outer, width: outer * 2, height: outer * 2))

        var glow = context
        glow.addFilter(.blur(radius: 3))
        glow.stroke(ring, with: .color(Color(hex: "#7C5CBF").opacity(0.65)), style: StrokeStyle(lineWidth: 2.5))

        context.stroke(ring, with: .color(Color(hex: "#C4A0FF")), style: StrokeStyle(lineWidth: 1.2))

        let inner: CGFloat = 1.6
        var dot = Path()
        dot.addEllipse(in: CGRect(x: point.x - inner, y: point.y - inner, width: inner * 2, height: inner * 2))
        context.fill(dot, with: .color(Color(hex: "#EDE8FA")))
    }

    private func drawIncompleteNode(in context: inout GraphicsContext, at point: CGPoint) {
        let outer: CGFloat = 4.5
        var ring = Path()
        ring.addEllipse(in: CGRect(x: point.x - outer, y: point.y - outer, width: outer * 2, height: outer * 2))
        context.stroke(
            ring,
            with: .color(Color(hex: "#2A1848").opacity(0.65)),
            style: StrokeStyle(lineWidth: 0.8),
        )
    }

    private func drawSummit(in context: inout GraphicsContext, geom: MountainGeometry, showStar: Bool) {
        if showStar {
            let star = geom.starPath(center: geom.apex, radius: 7)
            var glow = context
            glow.addFilter(.blur(radius: 4))
            glow.fill(star, with: .color(Color(hex: "#EDE8FA").opacity(0.45)))
            context.fill(star, with: .color(Color(hex: "#EDE8FA")))
            context.stroke(star, with: .color(Color.white.opacity(0.6)), style: StrokeStyle(lineWidth: 0.5))
        } else {
            let r: CGFloat = 4
            var circle = Path()
            circle.addEllipse(in: CGRect(x: geom.apex.x - r, y: geom.apex.y - r, width: r * 2, height: r * 2))
            context.stroke(circle, with: .color(Color(hex: "#2A1848").opacity(0.5)), style: StrokeStyle(lineWidth: 0.8))
        }
    }
}

// MARK: - Fixed geometry

private struct MountainGeometry {
    let apex = CGPoint(x: 117, y: 14)

    let leftFace: Path
    let rightFace: Path
    let centralFace: Path
    let leftRidgeLine: Path
    let rightRidgeLine: Path
    let ascentPath: Path
    let leftFacetLines: [Path]
    let rightFacetLines: [Path]
    let snowCap: Path

    init() {
        leftFace = Self.makePath([
            apex,
            CGPoint(x: 108, y: 26),
            CGPoint(x: 92, y: 48),
            CGPoint(x: 72, y: 72),
            CGPoint(x: 48, y: 98),
            CGPoint(x: 22, y: 122),
            CGPoint(x: 0, y: 138),
            CGPoint(x: 117, y: 138),
        ])

        rightFace = Self.makePath([
            apex,
            CGPoint(x: 126, y: 28),
            CGPoint(x: 142, y: 52),
            CGPoint(x: 162, y: 78),
            CGPoint(x: 186, y: 104),
            CGPoint(x: 210, y: 126),
            CGPoint(x: 234, y: 138),
            CGPoint(x: 117, y: 138),
        ])

        centralFace = Self.makePath([
            apex,
            CGPoint(x: 108, y: 26),
            CGPoint(x: 117, y: 138),
            CGPoint(x: 126, y: 28),
        ])

        leftRidgeLine = Self.makeOpenPath([
            CGPoint(x: 18, y: 128),
            CGPoint(x: 34, y: 108),
            CGPoint(x: 52, y: 86),
            CGPoint(x: 68, y: 66),
            CGPoint(x: 84, y: 48),
            CGPoint(x: 98, y: 32),
            CGPoint(x: 108, y: 22),
            apex,
        ])

        rightRidgeLine = Self.makeOpenPath([
            apex,
            CGPoint(x: 128, y: 30),
            CGPoint(x: 148, y: 54),
            CGPoint(x: 172, y: 82),
            CGPoint(x: 198, y: 110),
            CGPoint(x: 222, y: 132),
        ])

        ascentPath = Self.makeOpenPath([
            CGPoint(x: 24, y: 124),
            CGPoint(x: 38, y: 104),
            CGPoint(x: 54, y: 84),
            CGPoint(x: 70, y: 64),
            CGPoint(x: 86, y: 46),
            CGPoint(x: 100, y: 30),
            CGPoint(x: 110, y: 20),
            apex,
        ])

        leftFacetLines = [
            Self.makeOpenPath([CGPoint(x: 108, y: 26), CGPoint(x: 72, y: 72), CGPoint(x: 48, y: 98)]),
            Self.makeOpenPath([CGPoint(x: 92, y: 48), CGPoint(x: 117, y: 138)]),
            Self.makeOpenPath([CGPoint(x: 68, y: 66), CGPoint(x: 22, y: 122)]),
            Self.makeOpenPath([apex, CGPoint(x: 84, y: 48), CGPoint(x: 48, y: 98)]),
        ]

        rightFacetLines = [
            Self.makeOpenPath([CGPoint(x: 126, y: 28), CGPoint(x: 162, y: 78), CGPoint(x: 186, y: 104)]),
            Self.makeOpenPath([CGPoint(x: 142, y: 52), CGPoint(x: 117, y: 138)]),
            Self.makeOpenPath([CGPoint(x: 172, y: 82), CGPoint(x: 210, y: 126)]),
        ]

        snowCap = Self.makePath([
            apex,
            CGPoint(x: 104, y: 24),
            CGPoint(x: 92, y: 34),
            CGPoint(x: 108, y: 38),
            CGPoint(x: 130, y: 36),
            CGPoint(x: 128, y: 26),
        ])
    }

    func nodePoints(count: Int) -> [CGPoint] {
        let spine: [CGPoint] = [
            CGPoint(x: 24, y: 124),
            CGPoint(x: 38, y: 104),
            CGPoint(x: 54, y: 84),
            CGPoint(x: 70, y: 64),
            CGPoint(x: 86, y: 46),
            CGPoint(x: 100, y: 30),
            CGPoint(x: 110, y: 20),
        ]
        guard count > 0 else { return [] }

        var cumulative: [CGFloat] = [0]
        for i in 1 ..< spine.count {
            let dx = spine[i].x - spine[i - 1].x
            let dy = spine[i].y - spine[i - 1].y
            cumulative.append(cumulative[i - 1] + hypot(dx, dy))
        }
        guard let totalLen = cumulative.last, totalLen > 0 else { return [] }

        return (0 ..< count).map { index in
            let t = CGFloat(index + 1) / CGFloat(count + 1)
            let target = t * totalLen
            for i in 1 ..< cumulative.count where cumulative[i] >= target {
                let seg = cumulative[i] - cumulative[i - 1]
                let local = seg > 0 ? (target - cumulative[i - 1]) / seg : 0
                let x = spine[i - 1].x + (spine[i].x - spine[i - 1].x) * local
                let y = spine[i - 1].y + (spine[i].y - spine[i - 1].y) * local
                return CGPoint(x: x, y: y)
            }
            return spine[spine.count - 1]
        }
    }

    func trimmedAscentPath(fraction: Double) -> Path {
        let spine: [CGPoint] = [
            CGPoint(x: 24, y: 124),
            CGPoint(x: 38, y: 104),
            CGPoint(x: 54, y: 84),
            CGPoint(x: 70, y: 64),
            CGPoint(x: 86, y: 46),
            CGPoint(x: 100, y: 30),
            CGPoint(x: 110, y: 20),
            apex,
        ]
        guard fraction >= 1 else {
            return Self.openPath(spine, fraction: max(0, fraction))
        }
        return ascentPath
    }

    private static func openPath(_ points: [CGPoint], fraction: Double) -> Path {
        guard points.count >= 2 else { return Path() }

        var cumulative: [CGFloat] = [0]
        for i in 1 ..< points.count {
            let dx = points[i].x - points[i - 1].x
            let dy = points[i].y - points[i - 1].y
            cumulative.append(cumulative[i - 1] + hypot(dx, dy))
        }
        guard let total = cumulative.last, total > 0 else { return Path() }

        let cut = CGFloat(fraction) * total
        var result = Path()
        result.move(to: points[0])
        for i in 1 ..< points.count {
            if cumulative[i] <= cut {
                result.addLine(to: points[i])
            } else {
                let segLen = cumulative[i] - cumulative[i - 1]
                let t = segLen > 0 ? (cut - cumulative[i - 1]) / segLen : 0
                let x = points[i - 1].x + (points[i].x - points[i - 1].x) * t
                let y = points[i - 1].y + (points[i].y - points[i - 1].y) * t
                result.addLine(to: CGPoint(x: x, y: y))
                break
            }
        }
        return result
    }

    func starPath(center: CGPoint, radius: CGFloat) -> Path {
        var path = Path()
        let points = 5
        let inner = radius * 0.42
        for i in 0 ..< points * 2 {
            let angle = (Double(i) * .pi / Double(points)) - .pi / 2
            let r = i.isMultiple(of: 2) ? radius : inner
            let x = center.x + CGFloat(cos(angle)) * r
            let y = center.y + CGFloat(sin(angle)) * r
            if i == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }

    private static func makePath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        path.closeSubpath()
        return path
    }

    private static func makeOpenPath(_ points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        return path
    }
}
