import CairnCore
import SwiftUI

struct ValueRow: View {
    let label: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CairnSpacing.size2) {
                Text(label)
                    .font(.cairnLabel.weight(.medium))
                    .foregroundStyle(Color.cairnTextPrimary)
                Spacer(minLength: 0)
                Text(value)
                    .font(.cairnMono)
                    .foregroundStyle(Color.cairnTextSecondary)
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cairnTextTertiary)
            }
            .padding(.vertical, CairnSpacing.size3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
