import CairnCore
import SwiftUI

struct WatchCaptureView: View {
    let onCapture: (MomentCategory) -> Void
    let onClose: () -> Void

    private let columns = Array(
        repeating: GridItem(.flexible(), spacing: CairnSpacing.size2),
        count: 3
    )

    var body: some View {
        VStack(spacing: CairnSpacing.size2) {
            HStack {
                Text("What's here?")
                    .font(.cairnSerif(size: 16, weight: .regular))
                    .foregroundStyle(Color.cairnTextPrimary)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Color.cairnTextSecondary)
                        .frame(width: 22, height: 22)
                        .background(Color.cairnStone100, in: Circle())
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: columns, spacing: CairnSpacing.size2) {
                ForEach(MomentCategory.allCases, id: \.self) { category in
                    Button {
                        onCapture(category)
                    } label: {
                        CategoryDot(category: category, size: 46, filled: true)
                    }
                    .buttonStyle(.plain)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, CairnSpacing.size3)
        .padding(.top, CairnSpacing.size3)
        .padding(.bottom, CairnSpacing.size4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.cairnPaper)
    }
}
