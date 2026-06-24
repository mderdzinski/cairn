import CairnCore
import SwiftUI

struct ReminderCardHead: View {
    let systemImage: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: CairnSpacing.size3) {
            avatar
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.cairnBody.weight(.semibold))
                    .foregroundStyle(Color.cairnTextPrimary)
                Text(subtitle)
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: CairnSpacing.size2)
            CairnSwitch(isOn: $isOn, label: title)
        }
    }

    private var avatar: some View {
        ZStack {
            Circle()
                .fill(isOn ? Color.cairnAccentSoft : Color.cairnStone100)
            Image(systemName: systemImage)
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(isOn ? Color.cairnAccentInk : Color.cairnTextTertiary)
        }
        .frame(width: 38, height: 38)
        .animation(.easeOut(duration: 0.18), value: isOn)
    }
}
