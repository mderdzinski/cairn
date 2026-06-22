import CairnCore
import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cairnLabel.weight(.semibold))
            .foregroundStyle(Color.cairnTextOnAccent)
            .padding(.horizontal, CairnSpacing.size5)
            .padding(.vertical, CairnSpacing.size3)
            .frame(minHeight: CairnSpacing.touchMin)
            .background(configuration.isPressed ? Color.cairnAccentPress : Color.cairnAccent)
            .clipShape(Capsule())
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

struct GhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.cairnLabel.weight(.semibold))
            .foregroundStyle(Color.cairnTextSecondary)
            .padding(.horizontal, CairnSpacing.size5)
            .padding(.vertical, CairnSpacing.size3)
            .frame(minHeight: CairnSpacing.touchMin)
            .background(configuration.isPressed ? Color.cairnStone100 : Color.clear)
            .clipShape(Capsule())
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}
