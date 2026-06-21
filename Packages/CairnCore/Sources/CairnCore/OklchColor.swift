import Foundation
import SwiftUI

extension Color {
    static func fromOklch(_ lightness: Double, _ chroma: Double, _ hue: Double, alpha: Double = 1.0) -> Color {
        let rgb = oklchToCompandedSRGB(lightness: lightness, chroma: chroma, hue: hue)
        return Color(.displayP3, red: rgb.red, green: rgb.green, blue: rgb.blue, opacity: alpha)
    }
}

private struct LinearSRGB {
    let red: Double
    let green: Double
    let blue: Double
}

private func oklchToCompandedSRGB(lightness: Double, chroma: Double, hue: Double) -> LinearSRGB {
    let hueRadians = hue * .pi / 180.0
    let aChannel = chroma * cos(hueRadians)
    let bChannel = chroma * sin(hueRadians)

    let lPrime = lightness + 0.3963377774 * aChannel + 0.2158037573 * bChannel
    let mPrime = lightness - 0.1055613458 * aChannel - 0.0638541728 * bChannel
    let sPrime = lightness - 0.0894841775 * aChannel - 1.2914855480 * bChannel

    let lLong = lPrime * lPrime * lPrime
    let mLong = mPrime * mPrime * mPrime
    let sLong = sPrime * sPrime * sPrime

    let redLinear = 4.0767416621 * lLong - 3.3077115913 * mLong + 0.2309699292 * sLong
    let greenLinear = -1.2684380046 * lLong + 2.6097574011 * mLong - 0.3413193965 * sLong
    let blueLinear = -0.0041960863 * lLong - 0.7034186147 * mLong + 1.7076147010 * sLong

    return LinearSRGB(
        red: compandSRGB(redLinear),
        green: compandSRGB(greenLinear),
        blue: compandSRGB(blueLinear)
    )
}

private func compandSRGB(_ linear: Double) -> Double {
    let clamped = max(0.0, min(1.0, linear))
    if clamped <= 0.0031308 {
        return clamped * 12.92
    }
    return 1.055 * pow(clamped, 1.0 / 2.4) - 0.055
}
