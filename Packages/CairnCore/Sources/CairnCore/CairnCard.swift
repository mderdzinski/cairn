import SwiftUI

public struct CairnCardModifier: ViewModifier {
    public enum Elevation {
        case flat
        case low
        case raised
        case sunken
    }

    public enum Padding {
        case none
        case small
        case medium
        case large

        var value: CGFloat {
            switch self {
            case .none: 0
            case .small: CairnSpacing.size4
            case .medium: CairnSpacing.size5
            case .large: CairnSpacing.size6
            }
        }
    }

    public let elevation: Elevation
    public let padding: Padding

    public init(elevation: Elevation = .low, padding: Padding = .medium) {
        self.elevation = elevation
        self.padding = padding
    }

    public func body(content: Content) -> some View {
        content
            .padding(padding.value)
            .background(background)
            .overlay(border)
            .clipShape(RoundedRectangle(cornerRadius: CairnRadii.card, style: .continuous))
            .compositingGroup()
            .shadow(
                color: shadowColor,
                radius: shadowRadius,
                x: 0,
                y: shadowY
            )
    }

    private var background: Color {
        switch elevation {
        case .sunken: .cairnBgSunken
        default: .cairnSurfaceCard
        }
    }

    @ViewBuilder
    private var border: some View {
        let strokeColor: Color = switch elevation {
        case .raised: .clear
        default: .cairnBorderSubtle
        }
        RoundedRectangle(cornerRadius: CairnRadii.card, style: .continuous)
            .strokeBorder(strokeColor, lineWidth: 1)
    }

    private var shadowColor: Color {
        switch elevation {
        case .flat, .sunken: .clear
        case .low: Color.cairnStone900.opacity(0.06)
        case .raised: Color.cairnStone900.opacity(0.10)
        }
    }

    private var shadowRadius: CGFloat {
        switch elevation {
        case .flat, .sunken: 0
        case .low: 4
        case .raised: 12
        }
    }

    private var shadowY: CGFloat {
        switch elevation {
        case .flat, .sunken: 0
        case .low: 2
        case .raised: 6
        }
    }
}

public extension View {
    func cairnCard(
        elevation: CairnCardModifier.Elevation = .low,
        padding: CairnCardModifier.Padding = .medium
    ) -> some View {
        modifier(CairnCardModifier(elevation: elevation, padding: padding))
    }
}
