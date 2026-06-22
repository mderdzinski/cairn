import SwiftUI

public struct CairnBadge: View {
    public enum Variant {
        case neutral
        case accent
        case outline
    }

    public let text: String
    public let variant: Variant
    public let isCount: Bool

    public init(_ text: String, variant: Variant = .neutral, isCount: Bool = false) {
        self.text = text
        self.variant = variant
        self.isCount = isCount
    }

    public var body: some View {
        Text(text)
            .font(font)
            .foregroundStyle(textColor)
            .padding(.horizontal, CairnSpacing.size2)
            .padding(.vertical, 5)
            .background(backgroundColor)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: CairnRadii.small, style: .continuous))
    }

    private var font: Font {
        if isCount {
            return .cairnMono(size: 12, weight: .semibold).monospacedDigit()
        }
        return .cairnLabel.weight(.semibold)
    }

    private var textColor: Color {
        switch variant {
        case .neutral: .cairnTextSecondary
        case .accent: .cairnAccentInk
        case .outline: .cairnTextSecondary
        }
    }

    private var backgroundColor: Color {
        switch variant {
        case .neutral: .cairnStone100
        case .accent: .cairnAccentSoft
        case .outline: .clear
        }
    }

    @ViewBuilder
    private var border: some View {
        if variant == .outline {
            RoundedRectangle(cornerRadius: CairnRadii.small, style: .continuous)
                .strokeBorder(Color.cairnBorderStrong, lineWidth: 1)
        }
    }
}
