import CairnCore
import SwiftUI

struct WeeklyTotalCard: View {
    let digest: PatternsDigest

    private var contentmentRatio: CGFloat {
        guard digest.total > 0 else { return 0 }
        return CGFloat(digest.split.contentment) / CGFloat(digest.total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(digest.total)")
                    .font(.cairnSerif(size: 36, weight: .light))
                    .foregroundStyle(Color.cairnTextPrimary)
                Spacer()
                Text("moments marked")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextSecondary)
            }

            ratioBar

            HStack {
                Label {
                    Text("\(digest.split.contentment) contentment")
                        .font(.cairnLabel.weight(.medium))
                } icon: {
                    Circle().fill(Color.cairnAccent).frame(width: 8, height: 8)
                }
                .foregroundStyle(Color.cairnAccentInk)
                Spacer()
                Label {
                    Text("\(digest.split.friction) friction")
                        .font(.cairnLabel.weight(.medium))
                } icon: {
                    Circle().fill(Color.cairnStone400).frame(width: 8, height: 8)
                }
                .foregroundStyle(Color.cairnTextPrimary)
            }
        }
        .cairnCard()
    }

    private var ratioBar: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                Color.cairnAccent
                    .frame(width: geo.size.width * contentmentRatio)
                Color.cairnStone300
            }
            .clipShape(Capsule())
        }
        .frame(height: 10)
    }
}

#Preview {
    WeeklyTotalCard(digest: PatternsDigest(
        moments: [
            Moment(timestamp: .now, category: .contentment),
            Moment(timestamp: .now, category: .contentment),
            Moment(timestamp: .now, category: .contentment),
            Moment(timestamp: .now, category: .aversion),
            Moment(timestamp: .now, category: .restlessness),
        ],
        range: .week
    ))
    .padding()
    .background(Color.cairnPaper)
}
