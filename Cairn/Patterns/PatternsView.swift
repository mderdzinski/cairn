import CairnCore
import SwiftData
import SwiftUI

struct PatternsView: View {
    @State private var range: PatternsRange = .week

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cairnPaper.ignoresSafeArea()
                PatternsContent(range: $range)
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
}

private struct PatternsContent: View {
    @Binding var range: PatternsRange
    @Query private var moments: [Moment]
    @Query(sort: \Moment.timestamp, order: .reverse) private var allMoments: [Moment]

    init(range: Binding<PatternsRange>) {
        _range = range
        let cutoff = MomentAggregates.cutoffDate(for: range.wrappedValue)
        _moments = Query(
            filter: #Predicate<Moment> { $0.timestamp >= cutoff },
            sort: \Moment.timestamp,
            order: .reverse
        )
    }

    private var digest: PatternsDigest {
        PatternsDigest(moments: moments, range: range)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CairnSpacing.size5) {
                header
                if moments.isEmpty {
                    emptyState
                } else {
                    WeeklyTotalCard(digest: digest)
                    RhythmCard(daily: digest.daily, range: range)
                    BreakdownCard(breakdown: digest.breakdown)
                }
            }
            .padding(.horizontal, CairnSpacing.size5)
            .padding(.top, CairnSpacing.size3)
            .padding(.bottom, CairnSpacing.size12)
        }
        .scrollContentBackground(.hidden)
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
}

#Preview {
    PatternsView()
        .modelContainer(for: Moment.self, inMemory: true)
}
