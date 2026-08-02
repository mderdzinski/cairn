import CairnCore
import SwiftData
import SwiftUI

struct PatternsView: View {
    @State private var range: PatternsRange = .week
    /// Day anchor for the query cutoff and digest. Re-derived on foreground and
    /// midnight so the week/month window can't go stale while the tab stays
    /// mounted — the same rollover fix Path and Capture already carry.
    @State private var dayStart = Calendar.current.startOfDay(for: .now)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cairnPaper.ignoresSafeArea()
                PatternsContent(range: $range, dayStart: dayStart)
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
            .refreshOnDayRollover(perform: refreshDayStart)
        }
    }

    private func refreshDayStart() {
        let start = Calendar.current.startOfDay(for: .now)
        if start != dayStart {
            dayStart = start
        }
    }
}

private struct DigestKey: Equatable {
    let count: Int
    let last: Date?
    let range: PatternsRange
    let day: Date
}

private struct PatternsContent: View {
    @Binding var range: PatternsRange
    let dayStart: Date
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Query private var moments: [Moment]
    @State private var hasAnyMoments: Bool = true
    @State private var digest: PatternsDigest?

    init(range: Binding<PatternsRange>, dayStart: Date) {
        _range = range
        self.dayStart = dayStart
        let cutoff = MomentAggregates.cutoffDate(for: range.wrappedValue, now: dayStart)
        _moments = Query(
            filter: #Predicate<Moment> { $0.timestamp >= cutoff },
            sort: \Moment.timestamp,
            order: .reverse
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CairnSpacing.size5) {
                header
                if moments.isEmpty {
                    emptyState
                } else if let digest {
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
        .task(id: DigestKey(count: moments.count, last: moments.first?.timestamp, range: range, day: dayStart)) {
            // dayStart as `now` pins the digest's day axis to the same anchor
            // as the query cutoff (both only use startOfDay).
            digest = PatternsDigest(moments: moments, range: range, now: dayStart)
        }
        .task {
            refreshHasAnyMoments()
            // The count-based onChange below misses 0 → 0 transitions (all
            // remaining moments deleted from another tab while this range is
            // already empty), leaving stale empty-state copy. Any save — local
            // or a CloudKit import — re-derives it.
            for await _ in NotificationCenter.default.notifications(named: ModelContext.didSave) {
                refreshHasAnyMoments()
            }
        }
        .onChange(of: moments.count) { _, _ in
            refreshHasAnyMoments()
        }
    }

    private func refreshHasAnyMoments() {
        let count = (try? modelContext.fetchCount(FetchDescriptor<Moment>())) ?? 0
        hasAnyMoments = count > 0
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
                        MotionGate.animate(reduceMotion: reduceMotion, .easeOut(duration: 0.2)) {
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
                .accessibilityHidden(true)
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
        hasAnyMoments ? "Nothing in this range" : "No moments yet"
    }

    private var emptyStateMessage: String {
        if !hasAnyMoments {
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
