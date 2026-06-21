import SwiftUI

public extension Font {
    static var cairnDisplay: Font {
        cairnSerif(size: 36, weight: .light)
    }

    static var cairnTitle: Font {
        cairnSerif(size: 28, weight: .regular)
    }

    static var cairnPrompt: Font {
        cairnSerif(size: 22, weight: .regular)
    }

    static var cairnBody: Font {
        cairnSans(size: 15, weight: .regular)
    }

    static var cairnLabel: Font {
        cairnSans(size: 13, weight: .medium)
    }

    static var cairnEyebrow: Font {
        cairnSans(size: 12, weight: .semibold)
    }

    static var cairnMono: Font {
        cairnMono(size: 13, weight: .regular)
    }

    static func cairnSerif(size: CGFloat, weight: Font.Weight) -> Font {
        .custom(spectralPostScriptName(for: weight), size: size)
    }

    static func cairnSans(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("HankenGrotesk-Regular", size: size).weight(weight)
    }

    static func cairnMono(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("SplineSansMono-Regular", size: size).weight(weight)
    }
}

private func spectralPostScriptName(for weight: Font.Weight) -> String {
    switch weight {
    case .ultraLight, .thin, .light: "Spectral-Light"
    case .medium: "Spectral-Medium"
    case .semibold: "Spectral-SemiBold"
    case .bold, .heavy, .black: "Spectral-Bold"
    default: "Spectral-Regular"
    }
}

public enum CairnTracking {
    public static let displayTight: CGFloat = -0.5
    public static let titleTight: CGFloat = -0.3
    public static let eyebrowCaps: CGFloat = 1.44
}
