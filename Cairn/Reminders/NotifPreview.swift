import CairnCore
import SwiftUI

struct NotifPreview: View {
    let bodyText: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: CairnSpacing.size2) {
                glyph
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("CAIRN")
                            .font(.cairnMono(size: 10, weight: .semibold))
                            .foregroundStyle(Color.cairnTextSecondary)
                            .tracking(0.6)
                        Spacer()
                        Text("now")
                            .font(.cairnMono(size: 10, weight: .regular))
                            .foregroundStyle(Color.cairnTextTertiary)
                    }
                    Text(bodyText)
                        .font(.cairnSerif(size: 14, weight: .regular))
                        .foregroundStyle(Color.cairnTextPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Image(systemName: "arrow.right")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.cairnTextTertiary)
            }
            .padding(.vertical, CairnSpacing.size2)
            .padding(.horizontal, CairnSpacing.size3)
            .background(Color.cairnSurfaceCard)
            .overlay(
                RoundedRectangle(cornerRadius: CairnRadii.medium, style: .continuous)
                    .strokeBorder(Color.cairnBorderSubtle, lineWidth: 1)
            )
            .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium, style: .continuous))
            .shadow(color: Color.cairnStone900.opacity(0.06), radius: 3, x: 0, y: 1)
        }
        .buttonStyle(.plain)
    }

    private var glyph: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 7, style: .continuous)
                .fill(Color.cairnBgSunken)
                .overlay(
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .strokeBorder(Color.cairnBorderSubtle, lineWidth: 1)
                )
            Image("CairnGlyph")
                .renderingMode(.template)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .padding(4)
                .foregroundStyle(Color.cairnStone600)
        }
        .frame(width: 30, height: 30)
    }
}
