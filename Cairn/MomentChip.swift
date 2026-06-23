import CairnCore
import SwiftUI

enum ChipSize {
    case small, medium, large

    var disc: CGFloat {
        switch self {
        case .small: 52
        case .medium: 72
        case .large: 96
        }
    }
}

struct MomentChip: View {
    let category: MomentCategory
    let size: ChipSize
    let action: () -> Void

    init(category: MomentCategory, size: ChipSize = .medium, action: @escaping () -> Void) {
        self.category = category
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: CairnSpacing.size2) {
                CategoryDot(
                    category: category,
                    size: size.disc,
                    showsGlyph: true,
                    filled: false
                )
                Text(category.displayName)
                    .font(.cairnLabel)
                    .foregroundStyle(CairnCategoryPalette.ink(category))
            }
        }
        .buttonStyle(MomentChipButtonStyle())
        .accessibilityLabel(Text(category.displayName))
        .accessibilityHint(Text(category.summary))
    }
}

private struct MomentChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 1 : 0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
