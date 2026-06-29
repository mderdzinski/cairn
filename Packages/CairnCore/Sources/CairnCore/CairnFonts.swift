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
        .custom(spectralPostScriptName(for: weight), size: size, relativeTo: textStyle(forSize: size))
    }

    static func cairnSans(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("HankenGrotesk-Regular", size: size, relativeTo: textStyle(forSize: size))
            .weight(weight)
    }

    static func cairnMono(size: CGFloat, weight: Font.Weight) -> Font {
        .custom("SplineSansMono-Regular", size: size, relativeTo: textStyle(forSize: size))
            .weight(weight)
    }

    /// Map a design pixel size to its nearest Apple text style so `Font.custom(_:size:relativeTo:)`
    /// scales the custom face the same way `Font.title`/`Font.body` would scale. Anchors fall
    /// roughly on Apple's HIG defaults: caption2 11, caption 12, footnote 13, subheadline 15,
    /// callout 16, body 17, headline 17, title3 20, title2 22, title 28, largeTitle 34+.
    private static func textStyle(forSize size: CGFloat) -> Font.TextStyle {
        switch size {
        case ..<12: .caption2
        case ..<13: .caption
        case ..<15: .footnote
        case ..<16: .subheadline
        case ..<17: .callout
        case ..<20: .body
        case ..<22: .title3
        case ..<28: .title2
        case ..<34: .title
        default: .largeTitle
        }
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
