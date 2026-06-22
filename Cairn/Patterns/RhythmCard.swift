import CairnCore
import SwiftUI

struct RhythmCard: View {
    let daily: [DailyTotals]
    let range: PatternsRange

    private var eyebrow: String {
        switch range {
        case .week: "Rhythm of the week"
        case .month: "Rhythm of the month"
        }
    }

    private var maxTotal: Int {
        max(daily.map(\.total).max() ?? 1, 1)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            Text(eyebrow)
                .font(.cairnEyebrow)
                .tracking(CairnTracking.eyebrowCaps)
                .foregroundStyle(Color.cairnTextTertiary)
                .textCase(.uppercase)

            GeometryReader { geo in
                HStack(alignment: .bottom, spacing: spacing(for: geo.size.width)) {
                    ForEach(daily, id: \.day) { day in
                        DailyBar(
                            day: day,
                            maxTotal: maxTotal,
                            showsLabel: shouldShowLabel(for: day),
                            availableHeight: geo.size.height
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(height: 96)
        }
        .cairnCard()
    }

    private func spacing(for width: CGFloat) -> CGFloat {
        guard daily.count > 1 else { return 0 }
        let maxSpacing: CGFloat = 8
        let minSpacing: CGFloat = 2
        let spacing = width / CGFloat(daily.count * 4)
        return min(maxSpacing, max(minSpacing, spacing))
    }

    private func shouldShowLabel(for day: DailyTotals) -> Bool {
        switch range {
        case .week:
            return true
        case .month:
            let weekday = Calendar.current.component(.weekday, from: day.day)
            return weekday == 2
        }
    }
}

private struct DailyBar: View {
    let day: DailyTotals
    let maxTotal: Int
    let showsLabel: Bool
    let availableHeight: CGFloat

    private var barHeight: CGFloat {
        let labelReserve: CGFloat = 16
        let usable = max(availableHeight - labelReserve, 16)
        guard day.total > 0 else { return 3 }
        let ratio = CGFloat(day.total) / CGFloat(maxTotal)
        return max(3, usable * ratio)
    }

    private var contentmentHeight: CGFloat {
        guard day.total > 0 else { return 0 }
        return barHeight * (CGFloat(day.contentment) / CGFloat(day.total))
    }

    private var hindranceHeight: CGFloat {
        barHeight - contentmentHeight
    }

    var body: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 0)
            VStack(spacing: 0) {
                Color.cairnAccent.frame(height: contentmentHeight)
                Color.cairnStone400.frame(height: hindranceHeight)
            }
            .frame(width: 14, height: barHeight)
            .clipShape(Capsule())
            Text(showsLabel ? dayLabel : " ")
                .font(.cairnMono(size: 11, weight: .regular))
                .foregroundStyle(Color.cairnTextTertiary)
                .frame(height: 12)
        }
        .frame(maxWidth: .infinity)
    }

    private var dayLabel: String {
        day.day.formatted(.dateTime.weekday(.narrow))
    }
}

#Preview {
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: .now)
    let totals = (0 ..< 7).reversed().map { offset -> DailyTotals in
        let day = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
        return DailyTotals(day: day, contentment: (offset + 1) % 4, hindrance: offset % 3)
    }
    return RhythmCard(daily: totals, range: .week)
        .padding()
        .background(Color.cairnPaper)
}
