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
        // Wrapper view so we can read accessibilityReduceMotion from @Environment —
        // ButtonStyle.makeBody itself is not a View context and can't.
        StyledLabel(configuration: configuration, style: self)
    }

    private struct StyledLabel: View {
        let configuration: Configuration
        let style: CairnButtonStyle

        @Environment(\.accessibilityReduceMotion) private var reduceMotion

        var body: some View {
            configuration.label
                .font(style.size.font.weight(.semibold))
                .foregroundStyle(style.foreground(pressed: configuration.isPressed))
                .padding(.horizontal, style.size.horizontalPadding)
                .padding(.vertical, CairnSpacing.size3)
                .frame(maxWidth: style.block ? .infinity : nil)
                .frame(minHeight: style.size.minHeight)
                .background(style.background(pressed: configuration.isPressed))
                .overlay(style.border)
                .clipShape(Capsule())
                .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
                .motionAwareAnimation(
                    .easeOut(duration: 0.12),
                    value: configuration.isPressed,
                    reduceMotion: reduceMotion
                )
        }
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
