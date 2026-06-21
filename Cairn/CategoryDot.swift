import CairnCore
import SwiftUI

struct CategoryDot: View {
    let category: MomentCategory
    var size: CGFloat = 32
    var showsGlyph: Bool = false

    var body: some View {
        Circle()
            .fill(CairnCategoryPalette.soft(category))
            .frame(width: size, height: size)
            .overlay {
                if showsGlyph {
                    Image(category.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: size * 0.62, height: size * 0.62)
                }
            }
    }
}
