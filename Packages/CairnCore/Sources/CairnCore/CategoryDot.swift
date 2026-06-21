import SwiftUI

public struct CategoryDot: View {
    public let category: MomentCategory
    public var size: CGFloat
    public var showsGlyph: Bool
    public var filled: Bool

    public init(category: MomentCategory, size: CGFloat = 32, showsGlyph: Bool = false, filled: Bool = false) {
        self.category = category
        self.size = size
        self.showsGlyph = showsGlyph
        self.filled = filled
    }

    private var shouldShowGlyph: Bool {
        filled || showsGlyph
    }

    private var glyphSize: CGFloat {
        size * (filled ? 0.66 : 0.62)
    }

    public var body: some View {
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
