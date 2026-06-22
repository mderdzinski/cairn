import SwiftUI

public struct CairnTag: View {
    public let label: String
    public let isSelected: Bool
    public let isSelectable: Bool
    public let action: (() -> Void)?

    public init(
        _ label: String,
        isSelected: Bool = false,
        isSelectable: Bool = false,
        action: (() -> Void)? = nil
    ) {
        self.label = label
        self.isSelected = isSelected
        self.isSelectable = isSelectable
        self.action = action
    }

    public var body: some View {
        if isSelectable {
            Button(action: handleTap) {
                content
            }
            .buttonStyle(.plain)
            .accessibilityAddTraits(isSelected ? .isSelected : [])
        } else {
            content
        }
    }

    private func handleTap() {
        action?()
    }

    private var content: some View {
        Text(label)
            .font(.cairnLabel.weight(.medium))
            .foregroundStyle(textColor)
            .padding(.horizontal, CairnSpacing.size3)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .overlay(border)
            .clipShape(Capsule())
    }

    private var textColor: Color {
        isSelected ? .cairnAccentInk : .cairnTextSecondary
    }

    private var backgroundColor: Color {
        isSelected ? .cairnAccentSoft : .cairnSurfaceCard
    }

    @ViewBuilder
    private var border: some View {
        if !isSelected {
            Capsule().strokeBorder(Color.cairnBorderDefault, lineWidth: 1)
        }
    }
}
