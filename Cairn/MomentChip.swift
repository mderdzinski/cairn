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
    let isSelected: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        category: MomentCategory,
        size: ChipSize = .medium,
        isSelected: Bool = false,
        action: @escaping () -> Void
    ) {
        self.category = category
        self.size = size
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: CairnSpacing.size2) {
                CategoryDot(
                    category: category,
                    size: size.disc,
                    showsGlyph: true,
                    filled: isSelected
                )
                Text(category.displayName)
                    .font(.cairnLabel)
                    .foregroundStyle(CairnCategoryPalette.ink(category))
            }
        }
        .buttonStyle(MomentChipButtonStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(Text(category.displayName))
        .accessibilityHint(Text(category.summary))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

private struct MomentChipButtonStyle: ButtonStyle {
    let reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.95 : 1.0)
            .offset(y: configuration.isPressed && !reduceMotion ? 1 : 0)
            .motionAwareAnimation(
                .easeOut(duration: 0.14),
                value: configuration.isPressed,
                reduceMotion: reduceMotion
            )
    }
}
