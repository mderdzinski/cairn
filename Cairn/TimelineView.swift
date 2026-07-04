import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncStatusMonitor.self) private var syncMonitor

    @State private var moments: [Moment] = []
    /// Flips true when a page-in returns fewer than the page size — that's the only
    /// definitive signal SwiftData gives us that there are no older moments in the
    /// store. Long gaps in capture history don't trigger this: cursor-based paging
    /// just keeps flowing across them until the fetch genuinely runs dry.
    @State private var hasReachedStart = false
    /// Guards concurrent load attempts on rapid scroll or overlapping onAppear firings.
    @State private var isLoading = false
    /// Cheap all-time count via fetchCount. Drives the "no moments at all" empty state.
    @State private var totalStoreCount = 0
    /// Cheap trailing-7-day count via fetchCount. Drives the headline copy.
    @State private var pastWeekCount = 0
    /// Cheap all-time count of moments with no reflection via fetchCount. Drives the
    /// "N moments waiting for reflection" banner — has to be a store-level query
    /// because filtering the paged slice would undercount a user with older
    /// unreflected moments below the current scroll position.
    @State private var unreflectedCount = 0

    @State private var reflectingMoment: Moment?

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
                // the newest page (so captures made on other tabs / the watch show up)
                // and merges with anything older we've paged in — so scroll position
                // is preserved across tab switches.
                Task { await refreshInitialWindow() }
            }
            .onChange(of: reflectingMoment) { previous, current in
                // The sheet just dismissed. A reflection may have been saved (or
                // cleared) — refresh counts so the "N waiting for reflection" banner
                // reflects the just-changed state instead of waiting for the next
                // tab switch.
                if previous != nil, current == nil {
                    refreshCounts()
                }
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
                    Task { await loadMore() }
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

    private var pageSize: Int {
        MomentTimelineFetcher.defaultPageSize
    }

    /// Fires on first appear and every tab switch back to Path. Refetches the newest
    /// page (`pageSize` most recent moments) and merges with anything older we've
    /// already paged in, so a capture made on another tab shows up here without
    /// scrapping paginated scroll position. Dedupes by id.
    private func refreshInitialWindow() async {
        refreshCounts()
        guard !isLoading else { return }
        let fresh = (try? modelContext.fetch(
            MomentTimelineFetcher.descriptorBefore(.now, limit: pageSize)
        )) ?? []
        let freshIDs = Set(fresh.map(\.id))
        let older = moments.filter { !freshIDs.contains($0.id) }
        moments = fresh + older
        // If the newest page came back with fewer than a full page AND nothing older
        // is paged in, there is no more history to load.
        hasReachedStart = fresh.count < pageSize && older.isEmpty
    }

    /// Called by the tail sentinel. Fetches the next page of moments strictly older
    /// than the current oldest in `moments`. Cursor-based paging is gap-tolerant: a
    /// user with a long stretch of no captures doesn't get a false "start of your
    /// path" — the fetch just skips the empty stretch and returns older moments.
    /// Only marks `hasReachedStart` when a page returns fewer than `pageSize` results,
    /// which is SwiftData's definitive signal there's nothing more.
    private func loadMore() async {
        guard !isLoading, !hasReachedStart else { return }
        guard let cursor = moments.last?.timestamp else {
            // Nothing loaded yet — refreshInitialWindow will handle this via .onAppear.
            return
        }
        isLoading = true
        defer { isLoading = false }
        let descriptor = MomentTimelineFetcher.descriptorBefore(cursor, limit: pageSize)
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        // Cursor predicate is inclusive (`<= cursor`) so ties at the boundary don't
        // fall through the crack of a strict `<`. Dedupe by id before appending —
        // in the common no-tie case that means one row of overlap per page.
        let seen = Set(moments.map(\.id))
        let fresh = fetched.filter { !seen.contains($0.id) }
        moments.append(contentsOf: fresh)
        // Terminate on either signal:
        //  - fewer results than pageSize: SwiftData confirms nothing more exists.
        //  - fresh is empty despite a full page: we're stuck on a tie cluster of
        //    ≥ pageSize moments sharing an identical timestamp. Doubling limits or
        //    switching to a compound cursor would recover this, but requiring >=50
        //    moments at the same instant means a scripted bulk import or an internal
        //    bug — not a real-user scenario. Terminate cleanly instead of spinning.
        if fetched.count < pageSize || fresh.isEmpty {
            hasReachedStart = true
        }
    }

    /// Runs the cheap fetch-count queries used by the header, banner, and empty state.
    private func refreshCounts() {
        totalStoreCount = (try? modelContext.fetchCount(FetchDescriptor<Moment>())) ?? 0
        pastWeekCount = (try? modelContext.fetchCount(
            MomentTimelineFetcher.pastWeekCountDescriptor()
        )) ?? 0
        unreflectedCount = (try? modelContext.fetchCount(
            MomentTimelineFetcher.unreflectedCountDescriptor()
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
