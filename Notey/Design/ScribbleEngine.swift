import SwiftUI
import AppKit
import CoreGraphics


enum ScribbleEngine {


    static let penCubicBezier = (x1: 0.65, y1: 0.0, x2: 0.35, y2: 1.0)
    static let checkDuration: Double = 0.20
    static let strikeDelay: Double = 0.14
    static let fadeDuration: Double = 0.18


    static func fnv1aHash(_ text: String) -> UInt32 {
        var h: UInt32 = 2166136261
        for byte in text.utf8 {
            h ^= UInt32(byte)
            h = h &* 16777619
        }
        return h
    }


    struct Random: Sendable {
        private var a: UInt32

        init(seed: UInt32) {
            self.a = seed
        }

        mutating func nextDouble() -> Double {
            a = a &+ 0x6d2b79f5
            let x = a ^ (a >> 15)
            let y = 1 | a
            var t = x &* y
            let term = (t ^ (t >> 7)) &* (61 | t)
            t = (t &+ term) ^ t
            return Double(t ^ (t >> 14)) / 4294967296.0
        }

        mutating func between(_ min: CGFloat, _ max: CGFloat) -> CGFloat {
            CGFloat(min + CGFloat(nextDouble()) * (max - min))
        }

        mutating func nextBool(probability: Double) -> Bool {
            nextDouble() < probability
        }
    }


    static func penEase(_ t: Double) -> Double {
        if t <= 0 { return 0 }
        if t >= 1 { return 1 }
        let (x1, y1, x2, y2) = penCubicBezier
        var s = t
        for _ in 0..<8 {
            let oneMinusS = 1.0 - s
            let x = 3.0 * oneMinusS * oneMinusS * s * x1 + 3.0 * oneMinusS * s * s * x2 + s * s * s
            let dx = 3.0 * oneMinusS * oneMinusS * x1 + 6.0 * oneMinusS * s * (x2 - x1) + 3.0 * s * s * (1.0 - x2)
            let diff = x - t
            if abs(diff) < 1e-5 { break }
            if abs(dx) < 1e-5 { break }
            s -= diff / dx
            s = max(0, min(1, s))
        }
        let oneMinusS = 1.0 - s
        return 3.0 * oneMinusS * oneMinusS * s * y1 + 3.0 * oneMinusS * s * s * y2 + s * s * s
    }


    static func splitCubic(p0: CGPoint, p1: CGPoint, p2: CGPoint, p3: CGPoint, at u: CGFloat) -> (CGPoint, CGPoint, CGPoint, CGPoint) {
        let uClamped = max(0, min(1, u))
        let p01 = CGPoint(x: (1 - uClamped) * p0.x + uClamped * p1.x, y: (1 - uClamped) * p0.y + uClamped * p1.y)
        let p12 = CGPoint(x: (1 - uClamped) * p1.x + uClamped * p2.x, y: (1 - uClamped) * p1.y + uClamped * p2.y)
        let p23 = CGPoint(x: (1 - uClamped) * p2.x + uClamped * p3.x, y: (1 - uClamped) * p2.y + uClamped * p3.y)

        let p012 = CGPoint(x: (1 - uClamped) * p01.x + uClamped * p12.x, y: (1 - uClamped) * p01.y + uClamped * p12.y)
        let p123 = CGPoint(x: (1 - uClamped) * p12.x + uClamped * p23.x, y: (1 - uClamped) * p12.y + uClamped * p23.y)

        let p0123 = CGPoint(x: (1 - uClamped) * p012.x + uClamped * p123.x, y: (1 - uClamped) * p012.y + uClamped * p123.y)

        return (p0, p01, p012, p0123)
    }

    static func splitQuad(p0: CGPoint, cp: CGPoint, p2: CGPoint, at u: CGFloat) -> (CGPoint, CGPoint, CGPoint) {
        let uClamped = max(0, min(1, u))
        let p01 = CGPoint(x: (1 - uClamped) * p0.x + uClamped * cp.x, y: (1 - uClamped) * p0.y + uClamped * cp.y)
        let p12 = CGPoint(x: (1 - uClamped) * cp.x + uClamped * p2.x, y: (1 - uClamped) * cp.y + uClamped * p2.y)
        let p012 = CGPoint(x: (1 - uClamped) * p01.x + uClamped * p12.x, y: (1 - uClamped) * p01.y + uClamped * p12.y)
        return (p0, p01, p012)
    }


    struct CheckmarkData: Sendable, Equatable {
        let start: CGPoint
        let valley: CGPoint
        let end: CGPoint
        let cp1: CGPoint
        let cp2: CGPoint
        let cp3: CGPoint
        let cp4: CGPoint
        let hookCp: CGPoint?
        let hookEnd: CGPoint?
        let width: CGFloat

        var hasHook: Bool { hookCp != nil && hookEnd != nil }

        func cgPath(in boxRect: CGRect, progress: CGFloat = 1.0) -> CGPath {
            let path = CGMutablePath()
            let p = max(0, min(1, progress))
            guard p > 0.001 else { return path }

            let scale = boxRect.width / 20.0
            let dx = -2.0 * scale
            let dy = -8.0 * scale
            let transform = CGAffineTransform(translationX: boxRect.minX + dx, y: boxRect.minY + dy)
                .scaledBy(x: scale, y: scale)

            let dipThreshold: CGFloat = 0.30
            let flickThreshold: CGFloat = hasHook ? 0.93 : 1.0

            if p <= dipThreshold {
                let u = p / dipThreshold
                let (p0, c1, c2, p3) = ScribbleEngine.splitCubic(p0: start, p1: cp1, p2: cp2, p3: valley, at: u)
                path.move(to: p0, transform: transform)
                path.addCurve(to: p3, control1: c1, control2: c2, transform: transform)
            } else if p <= flickThreshold {
                path.move(to: start, transform: transform)
                path.addCurve(to: valley, control1: cp1, control2: cp2, transform: transform)

                let u = (p - dipThreshold) / (flickThreshold - dipThreshold)
                let (_, c3, c4, pEnd) = ScribbleEngine.splitCubic(p0: valley, p1: cp3, p2: cp4, p3: end, at: u)
                path.addCurve(to: pEnd, control1: c3, control2: c4, transform: transform)
            } else {
                path.move(to: start, transform: transform)
                path.addCurve(to: valley, control1: cp1, control2: cp2, transform: transform)
                path.addCurve(to: end, control1: cp3, control2: cp4, transform: transform)

                if let hookCp = hookCp, let hookEnd = hookEnd {
                    let u = (p - flickThreshold) / (1.0 - flickThreshold)
                    let (_, hCp, hEnd) = ScribbleEngine.splitQuad(p0: end, cp: hookCp, p2: hookEnd, at: u)
                    path.addQuadCurve(to: hEnd, control: hCp, transform: transform)
                }
            }

            return path
        }
    }

    static func generateCheckmark(seed: UInt32) -> CheckmarkData {
        var rand = Random(seed: seed)
        let sx = rand.between(3.5, 7.0)
        let sy = rand.between(10.0, 14.0)

        let vx = sx + rand.between(3.5, 5.5)
        let vy = rand.between(16.5, 19.5)

        let angle = (rand.between(48.0, 68.0) * .pi) / 180.0
        let length = rand.between(15.0, 21.0)
        let ex = vx + cos(angle) * length
        let ey = vy - sin(angle) * length

        let dipBow = rand.between(-1.2, 1.4)
        let flickBow = rand.between(-2.2, 1.6)
        let nx = sin(angle)
        let ny = cos(angle)

        let cp1 = CGPoint(x: sx + 1.3 + dipBow, y: sy + 2.0 - dipBow * 0.5)
        let cp2 = CGPoint(x: vx - 1.8, y: vy - rand.between(0.2, 1.4))

        let cp3 = CGPoint(x: vx + (ex - vx) * 0.3 + nx * flickBow, y: vy + (ey - vy) * 0.3 + ny * flickBow)
        let cp4 = CGPoint(x: vx + (ex - vx) * 0.7 + nx * flickBow, y: vy + (ey - vy) * 0.7 + ny * flickBow)

        var hookCp: CGPoint? = nil
        var hookEnd: CGPoint? = nil
        if rand.nextBool(probability: 0.45) {
            let qdx1 = rand.between(0.6, 1.6)
            let qdy1 = rand.between(-0.6, 0.3)
            let qdx = rand.between(1.2, 2.6)
            let qdy = rand.between(0.4, 1.4)
            hookCp = CGPoint(x: ex + qdx1, y: ey + qdy1)
            hookEnd = CGPoint(x: ex + qdx, y: ey + qdy)
        }

        let width = rand.between(1.75, 2.3)

        return CheckmarkData(
            start: CGPoint(x: sx, y: sy),
            valley: CGPoint(x: vx, y: vy),
            end: CGPoint(x: ex, y: ey),
            cp1: cp1,
            cp2: cp2,
            cp3: cp3,
            cp4: cp4,
            hookCp: hookCp,
            hookEnd: hookEnd,
            width: width
        )
    }


    struct StrikeData: Sendable, Equatable {
        let start: CGPoint
        let cp1: CGPoint
        let cp2: CGPoint
        let end: CGPoint
        let width: CGFloat

        func cgPath(progress: CGFloat = 1.0) -> CGPath {
            let path = CGMutablePath()
            let p = max(0, min(1, progress))
            guard p > 0.001 else { return path }

            if p >= 0.999 {
                path.move(to: start)
                path.addCurve(to: end, control1: cp1, control2: cp2)
            } else {
                let (p0, c1, c2, p3) = ScribbleEngine.splitCubic(p0: start, p1: cp1, p2: cp2, p3: end, at: p)
                path.move(to: p0)
                path.addCurve(to: p3, control1: c1, control2: c2)
            }
            return path
        }
    }

    static func generateStrike(x0: CGFloat, x1: CGFloat, y: CGFloat, seed: UInt32) -> StrikeData {
        var rand = Random(seed: seed)
        let adjX0 = x0 - rand.between(1.0, 5.0)
        let adjX1 = x1 + rand.between(1.0, 6.0)
        let w = max(1.0, adjX1 - adjX0)

        let slope = rand.between(-2.0, 0.6)
        let startY = y - slope / 2.0 + rand.between(-0.6, 0.6)
        let endY = y + slope / 2.0 + rand.between(-0.6, 0.6)

        let cp1 = CGPoint(x: adjX0 + w * rand.between(0.25, 0.40), y: y + rand.between(-1.8, 1.8))
        let cp2 = CGPoint(x: adjX0 + w * rand.between(0.60, 0.75), y: y + rand.between(-1.8, 1.8))
        let width = rand.between(1.4, 1.9)

        return StrikeData(
            start: CGPoint(x: adjX0, y: startY),
            cp1: cp1,
            cp2: cp2,
            end: CGPoint(x: adjX1, y: endY),
            width: width
        )
    }

    static func strikeDuration(x0: CGFloat, x1: CGFloat) -> Double {
        let length = max(0, x1 - x0)
        let ms = min(260.0, max(120.0, Double(length) * 0.9))
        return ms / 1000.0
    }
}


struct ScribbleCheckmarkShape: Shape {
    var progress: CGFloat
    let data: ScribbleEngine.CheckmarkData

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    init(data: ScribbleEngine.CheckmarkData, progress: CGFloat = 1.0) {
        self.data = data
        self.progress = progress
    }

    func path(in rect: CGRect) -> Path {
        Path(data.cgPath(in: rect, progress: progress))
    }
}

struct ScribbleStrikeShape: Shape {
    var progress: CGFloat
    let data: ScribbleEngine.StrikeData

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    init(data: ScribbleEngine.StrikeData, progress: CGFloat = 1.0) {
        self.data = data
        self.progress = progress
    }

    func path(in rect: CGRect) -> Path {
        Path(data.cgPath(progress: progress))
    }
}


struct ScribbleCheckboxIcon: View {
    let checked: Bool
    let seed: UInt32
    let size: CGFloat
    let strokeColor: Color
    let fillColor: Color
    let checkColor: Color

    @State private var animatedProgress: CGFloat = 0.0
    @State private var animatedOpacity: Double = 0.0

    init(
        checked: Bool,
        seed: UInt32,
        size: CGFloat = 20,
        strokeColor: Color = Color.textPrimary.opacity(0.35),
        fillColor: Color = Color.textPrimary.opacity(0.04),
        checkColor: Color = Color.textPrimary
    ) {
        self.checked = checked
        self.seed = seed
        self.size = size
        self.strokeColor = strokeColor
        self.fillColor = fillColor
        self.checkColor = checkColor
        _animatedProgress = State(initialValue: checked ? 1.0 : 0.0)
        _animatedOpacity = State(initialValue: checked ? 1.0 : 0.0)
    }

    private var checkData: ScribbleEngine.CheckmarkData {
        ScribbleEngine.generateCheckmark(seed: seed)
    }

    var body: some View {
        let cornerRadius = (size / 20.0) * 5.5
        let borderWidth = max(1.2, (size / 20.0) * 1.5)
        let strokeWidth = checkData.width * (size / 20.0)

        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius)
                .stroke(strokeColor, lineWidth: borderWidth)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .fill(fillColor)
                )
                .frame(width: size, height: size)

            ScribbleCheckmarkShape(data: checkData, progress: animatedProgress)
                .stroke(
                    checkColor,
                    style: StrokeStyle(
                        lineWidth: strokeWidth,
                        lineCap: .round,
                        lineJoin: .round
                    )
                )
                .frame(width: size, height: size)
                .opacity(animatedOpacity)
        }
        .frame(width: size, height: size)
        .onChange(of: checked) { _, isNowChecked in
            if isNowChecked {
                animatedOpacity = 1.0
                animatedProgress = 0.0
                withAnimation(.timingCurve(0.65, 0, 0.35, 1, duration: ScribbleEngine.checkDuration)) {
                    animatedProgress = 1.0
                }
            } else {
                withAnimation(.easeOut(duration: ScribbleEngine.fadeDuration)) {
                    animatedOpacity = 0.0
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + ScribbleEngine.fadeDuration) {
                    if !checked {
                        animatedProgress = 0.0
                    }
                }
            }
        }
    }
}


struct ScribbleCheckbox<Content: View>: View {
    @Binding var isChecked: Bool
    let seed: UInt32
    let onToggle: ((Bool) -> Void)?
    let content: () -> Content

    @State private var currentSeed: UInt32
    @State private var isHovered = false
    @State private var isPressed = false

    init(
        isChecked: Binding<Bool>,
        seed: UInt32? = nil,
        onToggle: ((Bool) -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self._isChecked = isChecked
        let initialSeed = seed ?? UInt32.random(in: 1...UInt32.max)
        self.seed = initialSeed
        self._currentSeed = State(initialValue: initialSeed)
        self.onToggle = onToggle
        self.content = content
    }

    var body: some View {
        Button(action: {
            let next = !isChecked
            if next {
                currentSeed = UInt32.random(in: 1...UInt32.max)
            }
            isChecked = next
            onToggle?(next)
        }) {
            HStack(alignment: .top, spacing: 10) {
                ScribbleCheckboxIcon(
                    checked: isChecked,
                    seed: currentSeed,
                    size: 20,
                    strokeColor: isHovered ? Color.textPrimary.opacity(0.55) : Color.textPrimary.opacity(0.35)
                )
                .scaleEffect(isPressed ? 0.96 : 1.0)
                .animation(.spring(response: 0.15, dampingFraction: 0.8), value: isPressed)

                content()
                    .foregroundColor(isChecked ? Color.textMuted : Color.textPrimary)
                    .animation(.easeOut(duration: 0.2), value: isChecked)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}
