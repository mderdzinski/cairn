@testable import CairnCore
import Foundation
import Testing

@Suite("StoneStack")
struct StoneStackTests {
    // swiftlint:disable empty_count
    @Test("count clamps to 0...6")
    func clamps() {
        #expect(StoneStack(count: -1).count == 0)
        #expect(StoneStack(count: 0).count == 0)
        #expect(StoneStack(count: 7).count == 6)
        #expect(StoneStack(count: 4).count == 4)
    }

    // swiftlint:enable empty_count

    @Test("size unit values match design spec")
    func units() {
        #expect(StoneSize.small.unit == 7)
        #expect(StoneSize.medium.unit == 10)
        #expect(StoneSize.large.unit == 14)
    }

    @Test("size pxScale values match design spec")
    func scales() {
        #expect(StoneSize.small.pxScale == 0.9)
        #expect(StoneSize.medium.pxScale == 1.3)
        #expect(StoneSize.large.pxScale == 1.8)
    }

    @Test("slab has six vertices")
    func slabSix() {
        let pts = StoneGeometry.slabPoints(cx: 10, topY: 0, w: 8, h: 4, mirrored: false)
        #expect(pts.count == 6)
    }

    @Test("mirroring reflects x around cx")
    func mirror() {
        let cx: CGFloat = 10
        let normal = StoneGeometry.slabPoints(cx: cx, topY: 0, w: 8, h: 4, mirrored: false)
        let mirror = StoneGeometry.slabPoints(cx: cx, topY: 0, w: 8, h: 4, mirrored: true)
        for (n, m) in zip(normal, mirror) {
            #expect(abs((n.x - cx) + (m.x - cx)) < 0.0001)
            #expect(n.y == m.y)
        }
    }
}
