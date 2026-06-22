import CairnCore
import SwiftUI

struct WatchConfirmView: View {
    let category: MomentCategory

    @State private var appeared = false

    var body: some View {
        VStack(spacing: CairnSpacing.size3) {
            Spacer()
            CategoryDot(category: category, size: 72, filled: true)
                .opacity(appeared ? 1 : 0)
                .scaleEffect(appeared ? 1 : 0.85)
                .offset(y: appeared ? 0 : 8)
            VStack(spacing: 2) {
                Text("Marked")
                    .font(.cairnSerif(size: 22, weight: .light))
                    .foregroundStyle(Color.cairnTextPrimary)
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
