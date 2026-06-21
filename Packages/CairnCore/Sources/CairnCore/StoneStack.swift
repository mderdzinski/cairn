import SwiftUI

public enum StoneSize: Sendable {
    case small, medium, large

    var unit: CGFloat {
        switch self {
        case .small: 7
        case .medium: 10
        case .large: 14
        }
    }

    var pxScale: CGFloat {
        switch self {
        case .small: 0.9
        case .medium: 1.3
        case .large: 1.8
        }
    }
}

public struct StoneStack: View {
    let count: Int
    let size: StoneSize
    let crown: Bool

    public init(count: Int = 4, size: StoneSize = .medium, crown: Bool = true) {
        self.count = max(0, min(6, count))
        self.size = size
        self.crown = crown
    }

    public var body: some View {
        // swiftlint:disable:next empty_count
        if count == 0 {
            EmptyView()
        } else {
            stack
        }
    }

    private var stack: some View {
        let u = size.unit
        let baseW = StoneGeometry.baseW * u
        let stoneH = StoneGeometry.stoneH * u
        let gap = StoneGeometry.gap * u
        let viewW = baseW + StoneGeometry.viewboxPad * u
        let viewH = CGFloat(count) * stoneH + CGFloat(count - 1) * gap

        return Canvas { ctx, _ in
            for t in 0 ..< count {
                let bottomIdx = (count - 1) - t
                let w = baseW * (1 - StoneGeometry.taper * CGFloat(bottomIdx))
                let sign: CGFloat = t.isMultiple(of: 2) ? 1 : -1
                let offset = sign * u * (crown && t == 0
                    ? StoneGeometry.crownOffset
                    : StoneGeometry.stoneOffset)
                let cx = viewW / 2 + offset
                let topY = CGFloat(t) * (stoneH + gap)
                let mirrored = !t.isMultiple(of: 2)
                let pts = StoneGeometry.slabPoints(
                    cx: cx,
                    topY: topY,
                    w: w,
                    h: stoneH,
                    mirrored: mirrored
                )
                var path = Path()
                path.move(to: pts[0])
                for p in pts.dropFirst() {
                    path.addLine(to: p)
                }
                path.closeSubpath()
                ctx.fill(path, with: .color(color(for: t, bottomIdx: bottomIdx)))
            }
        }
        .frame(width: viewW, height: viewH)
        .scaleEffect(size.pxScale, anchor: .center)
        .frame(width: viewW * size.pxScale, height: viewH * size.pxScale)
        .accessibilityHidden(true)
    }

    private func color(for index: Int, bottomIdx: Int) -> Color {
        if crown, index == 0 { return .cairnSage500 }
        if bottomIdx == 0 { return .cairnStone700 }
        return bottomIdx.isMultiple(of: 2) ? .cairnStone600 : .cairnStone300
    }
}

enum StoneGeometry {
    static let baseW: CGFloat = 3.4
    static let stoneH: CGFloat = 1.18
    static let gap: CGFloat = 0.34
    static let taper: CGFloat = 0.12
    static let viewboxPad: CGFloat = 1.6
    static let crownOffset: CGFloat = 0.15
    static let stoneOffset: CGFloat = 0.32

    static func slabPoints(cx: CGFloat, topY: CGFloat, w: CGFloat, h: CGFloat, mirrored: Bool) -> [CGPoint] {
        let mx: CGFloat = mirrored ? -1 : 1
        return [
            CGPoint(x: cx + mx * (-w / 2), y: topY + h * 0.46),
            CGPoint(x: cx + mx * (-w * 0.16), y: topY + h * 0.04),
            CGPoint(x: cx + mx * (w * 0.32), y: topY),
            CGPoint(x: cx + mx * (w / 2), y: topY + h * 0.42),
            CGPoint(x: cx + mx * (w * 0.40), y: topY + h),
            CGPoint(x: cx + mx * (-w * 0.42), y: topY + h),
        ]
    }
}
