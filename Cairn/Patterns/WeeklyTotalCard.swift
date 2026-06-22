import CairnCore
import SwiftUI

struct WeeklyTotalCard: View {
    let moments: [Moment]

    private var split: (contentment: Int, friction: Int) {
        MomentAggregates.contentmentSplit(moments: moments)
    }

    private var total: Int {
        moments.count
    }

    private var contentmentRatio: CGFloat {
        guard total > 0 else { return 0 }
        return CGFloat(split.contentment) / CGFloat(total)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            HStack(alignment: .firstTextBaseline) {
                Text("\(total)")
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
                    Text("\(split.contentment) contentment")
                        .font(.cairnLabel.weight(.medium))
                } icon: {
                    Circle().fill(Color.cairnAccent).frame(width: 8, height: 8)
                }
                .foregroundStyle(Color.cairnAccentInk)
                Spacer()
                Label {
                    Text("\(split.friction) friction")
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
    WeeklyTotalCard(moments: [
        Moment(timestamp: .now, category: .contentment),
        Moment(timestamp: .now, category: .contentment),
        Moment(timestamp: .now, category: .contentment),
        Moment(timestamp: .now, category: .aversion),
        Moment(timestamp: .now, category: .restlessness),
    ])
    .padding()
    .background(Color.cairnPaper)
}
