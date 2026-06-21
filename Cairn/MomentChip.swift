import CairnCore
import SwiftUI

struct MomentChip: View {
    let category: MomentCategory
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: CairnSpacing.size2) {
                ZStack {
                    Circle().fill(CairnCategoryPalette.soft(category))
                    Image(systemName: placeholderSymbol(for: category))
                        .font(.system(size: 32, weight: .light))
                        .foregroundStyle(CairnCategoryPalette.ink(category))
                }
                .frame(width: 72, height: 72)
                Text(category.displayName)
                    .font(.cairnLabel)
                    .foregroundStyle(CairnCategoryPalette.ink(category))
            }
        }
        .buttonStyle(MomentChipButtonStyle())
        .accessibilityLabel(Text(category.displayName))
        .accessibilityHint(Text(category.summary))
    }

    private func placeholderSymbol(for category: MomentCategory) -> String {
        switch category {
        case .contentment: "leaf.fill"
        case .desire: "flame.fill"
        case .aversion: "shield.fill"
        case .restlessness: "scribble.variable"
        case .heaviness: "cloud.fill"
        case .doubt: "questionmark.circle.fill"
        }
    }
}

private struct MomentChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
