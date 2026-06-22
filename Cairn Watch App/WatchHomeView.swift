import CairnCore
import SwiftUI

struct WatchHomeView: View {
    let todayCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: CairnSpacing.size3) {
                Text(eyebrowDate)
                    .font(.cairnEyebrow)
                    .tracking(CairnTracking.eyebrowCaps)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .textCase(.uppercase)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Spacer(minLength: 0)

                StoneStack(count: min(todayCount, 6), size: .large)

                VStack(spacing: 2) {
                    Text(stoneCountLine)
                        .font(.cairnSerif(size: 20, weight: .regular))
                        .foregroundStyle(Color.cairnTextPrimary)
                    Text("Tap to mark a moment")
                        .font(.cairnLabel)
                        .foregroundStyle(Color.cairnTextSecondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, CairnSpacing.size4)
            .padding(.vertical, CairnSpacing.size3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .background(Color.cairnPaper)
    }

    private var eyebrowDate: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.abbreviated))
        let monthDay = Date.now.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)"
    }

    private var stoneCountLine: String {
        if todayCount == 0 {
            return "No stones yet"
        }
        return "\(todayCount) \(todayCount == 1 ? "stone" : "stones") today"
    }
}
