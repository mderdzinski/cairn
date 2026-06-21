import CairnCore
import SwiftUI

struct MarkedToast: View {
    let category: MomentCategory

    var body: some View {
        HStack(spacing: CairnSpacing.size2) {
            CategoryDot(category: category, size: 22, filled: true)
            Text("Marked · \(category.displayName)")
                .font(.cairnSans(size: 15, weight: .semibold))
                .foregroundStyle(Color.cairnStone50)
        }
        .padding(.leading, CairnSpacing.size3)
        .padding(.trailing, CairnSpacing.size4)
        .padding(.vertical, CairnSpacing.size2)
        .background(Color.cairnStone900, in: Capsule())
        .shadow(color: Color.cairnStone900.opacity(0.18), radius: 18, y: 6)
        .allowsHitTesting(false)
    }
}
