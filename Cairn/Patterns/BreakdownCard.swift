import CairnCore
import SwiftUI

struct BreakdownCard: View {
    let breakdown: [CategoryTotal]

    private var maxCount: Int {
        max(breakdown.map(\.count).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            Text("What you noticed")
                .font(.cairnEyebrow)
                .tracking(CairnTracking.eyebrowCaps)
                .foregroundStyle(Color.cairnTextTertiary)
                .textCase(.uppercase)

            VStack(spacing: CairnSpacing.size2) {
                ForEach(breakdown, id: \.category) { row in
                    BreakdownRow(total: row, maxCount: maxCount)
                }
            }
        }
        .cairnCard()
    }
}

private struct BreakdownRow: View {
    let total: CategoryTotal
    let maxCount: Int

    private var ratio: CGFloat {
        CGFloat(total.count) / CGFloat(maxCount)
    }

    var body: some View {
        HStack(spacing: CairnSpacing.size3) {
            CategoryDot(category: total.category, size: 18, filled: true)

            Text(total.category.displayName)
                .font(.cairnLabel.weight(.semibold))
                .foregroundStyle(Color.cairnTextPrimary)
                .frame(width: 96, alignment: .leading)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.cairnStone100)
                    Capsule()
                        .fill(CairnCategoryPalette.hue(total.category))
                        .frame(width: max(6, geo.size.width * ratio))
                }
            }
            .frame(height: 8)

            Text("\(total.count)")
                .font(.cairnMono)
                .monospacedDigit()
                .foregroundStyle(Color.cairnTextSecondary)
                .frame(width: 24, alignment: .trailing)
        }
    }
}

#Preview {
    BreakdownCard(breakdown: [
        CategoryTotal(category: .contentment, count: 12),
        CategoryTotal(category: .aversion, count: 8),
        CategoryTotal(category: .restlessness, count: 5),
        CategoryTotal(category: .doubt, count: 2),
    ])
    .padding()
    .background(Color.cairnPaper)
}
