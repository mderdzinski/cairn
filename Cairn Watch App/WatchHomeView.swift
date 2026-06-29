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

                if todayCount > 0 {
                    StoneStack(count: min(todayCount, 6), size: .medium)
                } else {
                    Capsule()
                        .fill(Color.cairnBorderStrong.opacity(0.7))
                        .frame(width: 34, height: 5)
                        .accessibilityHidden(true)
                }

                VStack(spacing: 2) {
                    Text(stoneCountLine)
                        .font(.cairnSerif(size: 20, weight: .regular))
                        .foregroundStyle(Color.cairnTextPrimary)
                    Text("What are you noticing?")
                        .font(.cairnSerif(size: 13, weight: .regular).italic())
                        .foregroundStyle(Color.cairnTextSecondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, CairnSpacing.size4)
            .padding(.vertical, CairnSpacing.size3)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .background(Color.cairnPaper)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Mark a moment"))
        .accessibilityValue(Text(stoneCountLine))
        .accessibilityHint(Text("Opens the capture screen"))
    }

    private var eyebrowDate: String {
        let weekday = Date.now.formatted(.dateTime.weekday(.abbreviated))
        let monthDay = Date.now.formatted(.dateTime.month(.abbreviated).day())
        return "\(weekday) · \(monthDay)"
    }

    private var stoneCountLine: String {
        if todayCount == 0 {
            return "Tap to mark one"
        }
        return "\(todayCount) \(todayCount == 1 ? "stone" : "stones") today"
    }
}
