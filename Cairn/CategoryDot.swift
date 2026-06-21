import CairnCore
import SwiftUI

struct CategoryDot: View {
    let category: MomentCategory
    var size: CGFloat = 32

    var body: some View {
        Circle()
            .fill(CairnCategoryPalette.soft(category))
            .frame(width: size, height: size)
    }
}
