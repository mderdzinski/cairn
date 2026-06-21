import CairnCore
import SwiftUI

struct CategoryDot: View {
    let category: MomentCategory
    var size: CGFloat = 32
    var showsGlyph: Bool = false
    var filled: Bool = false

    private var shouldShowGlyph: Bool {
        filled || showsGlyph
    }

    private var glyphSize: CGFloat {
        size * (filled ? 0.66 : 0.62)
    }

    var body: some View {
        Circle()
            .fill(CairnCategoryPalette.soft(category))
            .frame(width: size, height: size)
            .overlay {
                if filled {
                    Circle()
                        .strokeBorder(CairnCategoryPalette.hue(category), lineWidth: 2)
                }
            }
            .overlay {
                if shouldShowGlyph {
                    Image(category.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: glyphSize, height: glyphSize)
                }
            }
    }
}
