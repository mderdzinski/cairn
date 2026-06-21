import SwiftUI

public extension Color {
    static let cairnStone50 = Color.fromOklch(0.972, 0.006, 80)
    static let cairnStone100 = Color.fromOklch(0.944, 0.008, 78)
    static let cairnStone200 = Color.fromOklch(0.892, 0.010, 76)
    static let cairnStone300 = Color.fromOklch(0.822, 0.011, 74)
    static let cairnStone400 = Color.fromOklch(0.702, 0.013, 72)
    static let cairnStone500 = Color.fromOklch(0.586, 0.014, 70)
    static let cairnStone600 = Color.fromOklch(0.482, 0.014, 68)
    static let cairnStone700 = Color.fromOklch(0.392, 0.014, 66)
    static let cairnStone800 = Color.fromOklch(0.298, 0.013, 64)
    static let cairnStone900 = Color.fromOklch(0.224, 0.012, 62)

    static let cairnPaper = Color.fromOklch(0.978, 0.009, 86)
    static let cairnPaperDeep = Color.fromOklch(0.958, 0.011, 84)

    static let cairnSage50 = Color.fromOklch(0.965, 0.014, 150)
    static let cairnSage100 = Color.fromOklch(0.928, 0.026, 150)
    static let cairnSage200 = Color.fromOklch(0.872, 0.040, 150)
    static let cairnSage300 = Color.fromOklch(0.792, 0.052, 150)
    static let cairnSage400 = Color.fromOklch(0.706, 0.058, 151)
    static let cairnSage500 = Color.fromOklch(0.622, 0.060, 152)
    static let cairnSage600 = Color.fromOklch(0.532, 0.056, 153)
    static let cairnSage700 = Color.fromOklch(0.446, 0.048, 154)
    static let cairnSage800 = Color.fromOklch(0.366, 0.038, 155)
    static let cairnSage900 = Color.fromOklch(0.298, 0.030, 156)

    static let cairnBgApp = Color.cairnPaper
    static let cairnBgSunken = Color.cairnPaperDeep
    static let cairnSurfaceCard = Color.white
    static let cairnSurfaceOverlay = Color.fromOklch(0.998, 0.004, 86)

    static let cairnTextPrimary = Color.cairnStone900
    static let cairnTextSecondary = Color.cairnStone600
    static let cairnTextTertiary = Color.cairnStone500
    static let cairnTextOnAccent = Color.fromOklch(0.985, 0.012, 150)
    static let cairnTextInverse = Color.cairnStone50

    static let cairnBorderSubtle = Color.fromOklch(0.892, 0.010, 76, alpha: 0.7)
    static let cairnBorderDefault = Color.cairnStone200
    static let cairnBorderStrong = Color.cairnStone300

    static let cairnAccent = Color.cairnSage600
    static let cairnAccentHover = Color.cairnSage700
    static let cairnAccentPress = Color.cairnSage800
    static let cairnAccentSoft = Color.cairnSage100
    static let cairnAccentInk = Color.cairnSage800
    static let cairnFocusRing = Color.fromOklch(0.622, 0.060, 152, alpha: 0.45)
}

public enum CairnCategoryPalette {
    public static func hue(_ category: MomentCategory) -> Color {
        switch category {
        case .contentment: .cairnSage500
        case .desire: .fromOklch(0.708, 0.092, 72)
        case .aversion: .fromOklch(0.582, 0.108, 35)
        case .restlessness: .fromOklch(0.612, 0.052, 205)
        case .heaviness: .fromOklch(0.560, 0.038, 60)
        case .doubt: .fromOklch(0.588, 0.058, 245)
        }
    }

    public static func soft(_ category: MomentCategory) -> Color {
        switch category {
        case .contentment: .cairnSage100
        case .desire: .fromOklch(0.945, 0.034, 76)
        case .aversion: .fromOklch(0.930, 0.030, 38)
        case .restlessness: .fromOklch(0.935, 0.022, 204)
        case .heaviness: .fromOklch(0.930, 0.018, 64)
        case .doubt: .fromOklch(0.935, 0.022, 244)
        }
    }

    public static func ink(_ category: MomentCategory) -> Color {
        switch category {
        case .contentment: .cairnSage800
        case .desire: .fromOklch(0.498, 0.072, 66)
        case .aversion: .fromOklch(0.420, 0.090, 34)
        case .restlessness: .fromOklch(0.448, 0.044, 206)
        case .heaviness: .fromOklch(0.408, 0.032, 58)
        case .doubt: .fromOklch(0.430, 0.052, 246)
        }
    }
}
