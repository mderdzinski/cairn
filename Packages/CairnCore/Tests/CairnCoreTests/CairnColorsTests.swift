#if canImport(UIKit)
@testable import CairnCore
import Foundation
import SwiftUI
import Testing
import UIKit

private struct RGBA: Equatable {
    let red: CGFloat
    let green: CGFloat
    let blue: CGFloat
    let alpha: CGFloat
}

private func components(of color: Color) -> RGBA {
    var red: CGFloat = 0
    var green: CGFloat = 0
    var blue: CGFloat = 0
    var alpha: CGFloat = 0
    UIColor(color).getRed(&red, green: &green, blue: &blue, alpha: &alpha)
    return RGBA(red: red, green: green, blue: blue, alpha: alpha)
}

@Suite("OklchColor")
struct OklchColorTests {
    @Test("oklch(0, 0, 0) yields near-black")
    func oklchBlack() {
        let rgba = components(of: .fromOklch(0.0, 0.0, 0.0))
        #expect(rgba.red < 0.05)
        #expect(rgba.green < 0.05)
        #expect(rgba.blue < 0.05)
    }

    @Test("oklch(1, 0, 0) yields near-white")
    func oklchWhite() {
        let rgba = components(of: .fromOklch(1.0, 0.0, 0.0))
        #expect(rgba.red > 0.95)
        #expect(rgba.green > 0.95)
        #expect(rgba.blue > 0.95)
    }

    @Test("sage-600 is green-dominant")
    func sageIsGreen() {
        let rgba = components(of: .fromOklch(0.622, 0.060, 152))
        #expect(rgba.green > rgba.red)
        #expect(rgba.green > rgba.blue)
    }

    @Test("alpha parameter is preserved")
    func alphaPreserved() {
        let rgba = components(of: .fromOklch(0.5, 0.0, 0.0, alpha: 0.45))
        #expect(abs(rgba.alpha - 0.45) < 0.01)
    }
}

@Suite("CairnCategoryPalette")
struct CairnCategoryPaletteTests {
    @Test("contentment hue aliases sage-500")
    func contentmentIsSage() {
        #expect(CairnCategoryPalette.hue(.contentment) == Color.cairnSage500)
        #expect(CairnCategoryPalette.soft(.contentment) == Color.cairnSage100)
        #expect(CairnCategoryPalette.ink(.contentment) == Color.cairnSage800)
    }

    @Test("every category has a distinct hue/soft/ink triple", arguments: MomentCategory.allCases)
    func tripleIsDistinct(category: MomentCategory) {
        let hue = components(of: CairnCategoryPalette.hue(category))
        let soft = components(of: CairnCategoryPalette.soft(category))
        let ink = components(of: CairnCategoryPalette.ink(category))
        #expect(hue != soft)
        #expect(soft != ink)
        #expect(hue != ink)
    }
}
#endif
