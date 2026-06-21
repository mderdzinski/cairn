import CairnCore
import SwiftUI

struct WatchConfirmView: View {
    let category: MomentCategory
    let count: Int

    @State private var appeared = false

    var body: some View {
        VStack(spacing: CairnSpacing.size3) {
            Spacer()
            StoneStack(count: max(1, min(count, 6)), size: .medium)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.9)
                .offset(y: appeared ? 0 : 10)
            Text("Marked")
                .font(.cairnSerif(size: 22, weight: .light))
                .foregroundStyle(Color.cairnTextPrimary)
            HStack(spacing: CairnSpacing.size2) {
                Image(category.assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                Text(category.displayName)
                    .font(.cairnLabel.weight(.semibold))
                    .foregroundStyle(CairnCategoryPalette.ink(category))
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cairnPaper)
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                appeared = true
            }
        }
    }
}
