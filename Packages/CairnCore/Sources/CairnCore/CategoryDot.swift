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
            .fill(litTint)
            .frame(width: size, height: size)
            .overlay {
                Circle()
                    .stroke(ringColor, lineWidth: filled ? 2 : 1)
            }
            .overlay {
                Circle()
                    .fill(LinearGradient(
                        colors: [Color.white.opacity(0.50), Color.clear],
                        startPoint: .top,
                        endPoint: .center
                    ))
                    .blendMode(.plusLighter)
                    .allowsHitTesting(false)
            }
            .overlay {
                if shouldShowGlyph {
                    Image(category.assetName)
                        .resizable()
                        .scaledToFit()
                        .frame(width: glyphSize, height: glyphSize)
                }
            }
            .shadow(
                color: Color.cairnStone900.opacity(filled ? 0.12 : 0.10),
                radius: filled ? 4 : 2.5,
                x: 0,
                y: filled ? 3 : 2
            )
    }

    private var litTint: RadialGradient {
        RadialGradient(
            colors: [
                CairnCategoryPalette.soft(category).mix(with: .white, by: 0.6),
                CairnCategoryPalette.soft(category),
            ],
            center: UnitPoint(x: 0.5, y: 0.2),
            startRadius: 0,
            endRadius: size * 0.75
        )
    }

    private var ringColor: Color {
        filled
            ? CairnCategoryPalette.hue(category)
            : CairnCategoryPalette.hue(category).opacity(0.18)
    }
}
