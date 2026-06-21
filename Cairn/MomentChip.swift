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
                    Image(category.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
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
}

private struct MomentChipButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}
