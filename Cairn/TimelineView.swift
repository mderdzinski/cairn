import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncStatusMonitor.self) private var syncMonitor

    @State private var moments: [Moment] = []
    /// Trailing cutoff of what we've loaded — anything with `timestamp >= oldestLoaded`
    /// is either already in `moments` or was fetched and returned empty. Starts at
    /// 30 days before now.
    @State private var oldestLoaded: Date = Calendar.current.date(
        byAdding: .day, value: -30, to: .now
    ) ?? .now
    /// Flips true when a page-in returns zero rows — stops the sentinel from firing
    /// further loads and swaps in the "start of your path" caption.
    @State private var hasReachedStart = false
    /// Guards concurrent load attempts on rapid scroll or overlapping onAppear firings.
    @State private var isLoading = false
    /// Cheap all-time count via fetchCount. Drives the "no moments at all" empty state.
    @State private var totalStoreCount = 0
    /// Cheap trailing-7-day count via fetchCount. Drives the headline copy.
    @State private var pastWeekCount = 0

    @State private var reflectingMoment: Moment?

    private var unreflectedCount: Int {
        moments.lazy.filter { ($0.reflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }.count
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.cairnPaper.ignoresSafeArea()
                content
            }
            .navigationTitle("Path")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Path")
                        .font(.cairnTitle)
                        .foregroundStyle(Color.cairnTextPrimary)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    SyncStatusPip(status: syncMonitor.status)
                        .allowsHitTesting(false)
                }
            }
            .sheet(item: $reflectingMoment) { moment in
                ReflectSheet(
                    moment: moment,
                    onDismiss: { reflectingMoment = nil },
                    onDelete: { delete(moment) }
                )
            }
            .onAppear {
                // Fires on first appear and every tab switch back to Path. Refetches
                // the initial 30-day window (so captures made on other tabs / the
                // watch show up) and merges with anything older we've paged in — so
                // scroll position is preserved across tab switches.
                Task { await refreshInitialWindow() }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if totalStoreCount == 0 {
            emptyState
        } else {
            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.horizontal, CairnSpacing.gutter)
                    .padding(.top, CairnSpacing.size2)
                if unreflectedCount > 0 {
                    unreflectedBanner
                        .padding(.horizontal, CairnSpacing.gutter)
                        .padding(.top, CairnSpacing.size4)
                }
                list
            }
        }
    }

    private var header: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: CairnSpacing.size1) {
                Text("Your path")
                    .font(.cairnEyebrow)
                    .tracking(CairnTracking.eyebrowCaps)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .textCase(.uppercase)
                Text(headlineText)
                    .font(.cairnSerif(size: 28, weight: .light))
                    .foregroundStyle(Color.cairnTextPrimary)
            }
            Spacer(minLength: 0)
            StoneStack(count: min(max(pastWeekCount, 1), 6), size: .small)
                .alignmentGuide(.firstTextBaseline) { dim in dim[VerticalAlignment.center] }
        }
    }

    private var headlineText: String {
        let noun = pastWeekCount == 1 ? "moment" : "moments"
        return "\(pastWeekCount) \(noun) this week"
    }

    private var unreflectedBanner: some View {
        HStack(spacing: CairnSpacing.size2) {
            Image(systemName: "pencil")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Color.cairnAccentInk)
                .accessibilityHidden(true)
            Text("\(unreflectedCount) \(unreflectedCount == 1 ? "moment" : "moments") waiting for reflection")
                .font(.cairnLabel.weight(.medium))
                .foregroundStyle(Color.cairnAccentInk)
            Spacer(minLength: 0)
        }
        .padding(.vertical, CairnSpacing.size3)
        .padding(.horizontal, CairnSpacing.size3)
        .background(Color.cairnSage50)
        .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
    }

    private var list: some View {
        List {
            ForEach(groupedDays, id: \.self) { day in
                Section {
                    ForEach(grouped[day] ?? []) { moment in
                        TimelineEntry(moment: moment) {
                            reflectingMoment = moment
                        }
                        .listRowBackground(swipeRowBackground)
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                delete(moment)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                    }
                } header: {
                    Text(sectionTitle(for: day))
                        .font(.cairnEyebrow)
                        .tracking(CairnTracking.eyebrowCaps)
                        .foregroundStyle(Color.cairnTextTertiary)
                        .textCase(.uppercase)
                }
            }
            tailSentinel
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    @ViewBuilder
    private var tailSentinel: some View {
        if hasReachedStart {
            Section {
                Text("You've reached the start of your path.")
                    .font(.cairnLabel)
                    .foregroundStyle(Color.cairnTextTertiary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .padding(.vertical, CairnSpacing.size4)
            }
        } else {
            Section {
                HStack {
                    Spacer()
                    ProgressView()
                        .controlSize(.small)
                        .tint(Color.cairnTextTertiary)
                    Spacer()
                }
                .padding(.vertical, CairnSpacing.size3)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
                .onAppear {
                    Task { await loadNextMonth() }
                }
            }
        }
    }

    /// Row background with rounded trailing corners so the row sits neatly next to
    /// the trash button when swipe-to-delete reveals it. The inset-grouped section
    /// already clips the leading side to its rounded card outline; matching the
    /// trailing side here keeps the shape coherent across the swipe reveal.
    private var swipeRowBackground: some View {
        UnevenRoundedRectangle(
            topLeadingRadius: 0,
            bottomLeadingRadius: 0,
            bottomTrailingRadius: CairnRadii.medium,
            topTrailingRadius: CairnRadii.medium
        )
        .fill(Color.cairnSurfaceCard)
    }

    private var emptyState: some View {
        VStack(spacing: CairnSpacing.size3) {
            Image(systemName: "mountain.2")
                .font(.system(size: 32, weight: .light))
                .foregroundStyle(Color.cairnTextTertiary)
                .accessibilityHidden(true)
            Text("No moments yet")
                .font(.cairnSerif(size: 18, weight: .regular))
                .foregroundStyle(Color.cairnTextPrimary)
            Text("Capture your first moment to see it here.")
                .font(.cairnLabel)
                .foregroundStyle(Color.cairnTextSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, CairnSpacing.size12)
    }

    private var grouped: [Date: [Moment]] {
        Dictionary(grouping: moments) { Calendar.current.startOfDay(for: $0.timestamp) }
    }

    private var groupedDays: [Date] {
        grouped.keys.sorted(by: >)
    }

    private func sectionTitle(for day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return "Today" }
        if Calendar.current.isDateInYesterday(day) { return "Yesterday" }
        return day.formatted(date: .abbreviated, time: .omitted)
    }

    // MARK: - Data loading

    /// The trailing cutoff of the initial fetch — anything with `timestamp >=` this
    /// point is inside the first 30-day window.
    private var initialCutoff: Date {
        Calendar.current.date(byAdding: .day, value: -30, to: .now) ?? .now
    }

    /// Fires on first appear and every tab switch back to Path. Refetches the initial
    /// 30-day window and merges with anything older we've already paged in, so a
    /// capture made on another tab shows up here without scrapping paginated scroll
    /// position. Dedupes by id to guard against the case where `initialCutoff` has
    /// crept forward past what we originally paged (e.g. the view stayed alive across
    /// a day boundary).
    private func refreshInitialWindow() async {
        refreshCounts()
        guard !isLoading else { return }
        let cutoff = initialCutoff
        let descriptor = MomentTimelineFetcher.pageDescriptor(from: cutoff, until: .now)
        let fresh = (try? modelContext.fetch(descriptor)) ?? []
        let freshIDs = Set(fresh.map(\.id))
        let older = moments.filter { $0.timestamp < cutoff && !freshIDs.contains($0.id) }
        moments = fresh + older
    }

    /// Called by the tail sentinel. Advances `oldestLoaded` one month further back
    /// and appends what fell in that window. If nothing did, marks `hasReachedStart`
    /// so we stop firing.
    private func loadNextMonth() async {
        guard !isLoading, !hasReachedStart else { return }
        let currentOldest = oldestLoaded
        let nextOldest = Calendar.current.date(
            byAdding: .month, value: -1, to: currentOldest
        ) ?? currentOldest
        await loadWindow(from: nextOldest, until: currentOldest)
        oldestLoaded = nextOldest
    }

    /// Fetch and append moments in `[from, until)`. Sets `hasReachedStart` when the
    /// page-in returns nothing — the sentinel swaps to the "start of your path"
    /// caption on the next render.
    private func loadWindow(from: Date, until: Date) async {
        isLoading = true
        defer { isLoading = false }
        let descriptor = MomentTimelineFetcher.pageDescriptor(from: from, until: until)
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        if fetched.isEmpty {
            hasReachedStart = true
        } else {
            moments.append(contentsOf: fetched)
        }
    }

    /// Runs the two cheap fetch-count queries used by the header and empty state.
    private func refreshCounts() {
        totalStoreCount = (try? modelContext.fetchCount(FetchDescriptor<Moment>())) ?? 0
        pastWeekCount = (try? modelContext.fetchCount(
            MomentTimelineFetcher.pastWeekCountDescriptor()
        )) ?? 0
    }

    private func delete(_ moment: Moment) {
        if reflectingMoment?.id == moment.id {
            reflectingMoment = nil
        }
        modelContext.delete(moment)
        moments.removeAll { $0.id == moment.id }
        refreshCounts()
    }
}

#Preview {
    TimelineView()
        .modelContainer(for: Moment.self, inMemory: true)
        .environment(SyncStatusMonitor(backing: .inMemory))
}
