import SwiftUI

public struct CairnButtonStyle: ButtonStyle {
    public enum Variant {
        case primary
        case secondary
        case ghost
        case soft
    }

    public enum Size {
        case small
        case medium
        case large

        var minHeight: CGFloat {
            switch self {
            case .small: 36
            case .medium: CairnSpacing.touchMin
            case .large: 52
            }
        }

        var horizontalPadding: CGFloat {
            switch self {
            case .small: CairnSpacing.size4
            case .medium: CairnSpacing.size5
            case .large: CairnSpacing.size6
            }
        }

        var font: Font {
            switch self {
            case .small: .cairnLabel
            case .medium: .cairnLabel
            case .large: .cairnLabel
            }
        }
    }

    public let variant: Variant
    public let size: Size
    public let block: Bool

    public init(_ variant: Variant = .primary, size: Size = .medium, block: Bool = false) {
        self.variant = variant
        self.size = size
        self.block = block
    }

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(size.font.weight(.semibold))
            .foregroundStyle(foreground(pressed: configuration.isPressed))
            .padding(.horizontal, size.horizontalPadding)
            .padding(.vertical, CairnSpacing.size3)
            .frame(maxWidth: block ? .infinity : nil)
            .frame(minHeight: size.minHeight)
            .background(background(pressed: configuration.isPressed))
            .overlay(border)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }

    private func foreground(pressed _: Bool) -> Color {
        switch variant {
        case .primary: .cairnTextOnAccent
        case .secondary: .cairnTextPrimary
        case .ghost: .cairnTextSecondary
        case .soft: .cairnAccentInk
        }
    }

    private func background(pressed: Bool) -> Color {
        switch variant {
        case .primary: pressed ? .cairnAccentPress : .cairnAccent
        case .secondary: pressed ? .cairnStone50 : .cairnSurfaceCard
        case .ghost: pressed ? .cairnStone100 : .clear
        case .soft: pressed ? .cairnSage200 : .cairnAccentSoft
        }
    }

    @ViewBuilder
    private var border: some View {
        if variant == .secondary {
            Capsule().strokeBorder(Color.cairnBorderStrong, lineWidth: 1)
        }
    }
}
