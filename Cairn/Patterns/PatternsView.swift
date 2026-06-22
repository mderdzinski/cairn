import CairnCore
import SwiftData
import SwiftUI

struct PatternsView: View {
    @Query(sort: \Moment.timestamp, order: .reverse)
    private var allMoments: [Moment]

    @State private var range: PatternsRange = .week

    private var inRange: [Moment] {
        MomentAggregates.filter(moments: allMoments, within: range)
    }

    private var daily: [DailyTotals] {
        MomentAggregates.daily(moments: inRange, range: range)
    }

    private var breakdown: [CategoryTotal] {
        MomentAggregates.breakdown(moments: inRange)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cairnPaper.ignoresSafeArea()
                content
            }
            .navigationTitle("Patterns")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Patterns")
                        .font(.cairnTitle)
                        .foregroundStyle(Color.cairnTextPrimary)
                }
            }
        }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CairnSpacing.size5) {
                header
                if inRange.isEmpty {
                    emptyState
                } else {
                    WeeklyTotalCard(moments: inRange)
                    RhythmCard(daily: daily, range: range)
                    BreakdownCard(breakdown: breakdown)
                }
            }
            .padding(.horizontal, CairnSpacing.size5)
            .padding(.top, CairnSpacing.size3)
            .padding(.bottom, CairnSpacing.size12)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyState: some View {
        VStack(spacing: CairnSpacing.size3) {
            Image(systemName: "chart.bar")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.cairnTextTertiary)
            Text(emptyStateTitle)
                .font(.cairnSerif(size: 18, weight: .regular))
                .foregroundStyle(Color.cairnTextPrimary)
            Text(emptyStateMessage)
                .font(.cairnLabel)
                .foregroundStyle(Color.cairnTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CairnSpacing.size12)
    }

    private var emptyStateTitle: String {
        allMoments.isEmpty ? "No moments yet" : "Nothing in this range"
    }

    private var emptyStateMessage: String {
        if allMoments.isEmpty {
            return "Capture a moment to start seeing patterns."
        }
        return range == .week
            ? "Switch to This month to see older moments."
            : "Capture a moment to see it here."
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.size3) {
            Text("Patterns")
                .font(.cairnEyebrow)
                .tracking(CairnTracking.eyebrowCaps)
                .foregroundStyle(Color.cairnTextTertiary)
                .textCase(.uppercase)
            Text(range.displayName)
                .font(.cairnSerif(size: 28, weight: .light))
                .foregroundStyle(Color.cairnTextPrimary)
            HStack(spacing: CairnSpacing.size2) {
                ForEach(PatternsRange.allCases, id: \.self) { option in
                    CairnTag(
                        option.displayName,
                        isSelected: range == option,
                        isSelectable: true
                    ) {
                        withAnimation(.easeOut(duration: 0.2)) {
                            range = option
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    PatternsView()
        .modelContainer(for: Moment.self, inMemory: true)
}
