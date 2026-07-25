import CairnCore
import SwiftData
import SwiftUI

struct TimelineView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(SyncStatusMonitor.self) private var syncMonitor
    @Environment(\.scenePhase) private var scenePhase

    @State private var moments: [Moment] = []
    /// Flips true when a page returns fewer than pageSize results — that's the only
    /// definitive signal SwiftData gives us that there's nothing more strictly older
    /// than the compound (timestamp, id) cursor. Long gaps in capture history don't
    /// trigger this: cursor-based paging just keeps flowing across them until the
    /// fetch genuinely runs dry.
    @State private var hasReachedStart = false
    /// Guards concurrent load attempts on rapid scroll or overlapping onAppear firings.
    @State private var isLoading = false
    /// Cheap all-time count via fetchCount. Drives the "no moments at all" empty state.
    @State private var totalStoreCount = 0
    /// Cheap trailing-7-day count via fetchCount. Drives the headline copy.
    @State private var pastWeekCount = 0
    /// Cheap count of *recent* moments (trailing 7 days, same window as the "this
    /// week" headline) with no reflection, via fetchCount. Drives the "N moments
    /// waiting for reflection" banner. Store-level query rather than filtering the
    /// paged slice: it stays honest regardless of scroll position, and bounding it
    /// to the recent window keeps the prompt a gentle invitation instead of an
    /// ever-growing all-time backlog — older unreflected moments age out of it.
    @State private var recentUnreflectedCount = 0

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
            .onChange(of: scenePhase) { _, phase in
                // The week-bounded counts (headline and reflection banner) bake
                // their cutoff in at fetch time, so they go stale when the day
                // rolls over while Path stays mounted. Foregrounding after a
                // suspend that crossed midnight won't have delivered
                // NSCalendarDayChanged, so re-derive on every activation — same
                // pattern as CaptureView's today count.
                if phase == .active { refreshCounts() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                refreshCounts()
            }
            .task {
                // Restore the liveness we lost by moving off @Query. Any save on
                // any ModelContext — our own writes, but also CloudKit imports
                // syncing a watch capture — fires this notification. Refetch the
                // newest page and cheap counts so Path stays live while it's on
                // screen. The .task is cancelled when the view leaves the tree.
                // No debounce: refresh is idempotent and cheap (two fetchCount
                // queries plus a bounded page fetch), so back-to-back saves are
                // fine.
                for await _ in NotificationCenter.default.notifications(
                    named: ModelContext.didSave
                ) {
                    await refreshInitialWindow()
                }
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if totalStoreCount == 0 {
            emptyState
        } else {
            ScrollViewReader { proxy in
                VStack(alignment: .leading, spacing: 0) {
                    header
                        .padding(.horizontal, CairnSpacing.gutter)
                        .padding(.top, CairnSpacing.size2)
                    if recentUnreflectedCount > 0 {
                        unreflectedBanner(proxy: proxy)
                            .padding(.horizontal, CairnSpacing.gutter)
                            .padding(.top, CairnSpacing.size4)
                    }
                    list
                }
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

    private var bannerText: String {
        let noun = recentUnreflectedCount == 1 ? "moment" : "moments"
        return "\(recentUnreflectedCount) \(noun) waiting for reflection"
    }

    private func unreflectedBanner(proxy: ScrollViewProxy) -> some View {
        Button {
            scrollToFirstUnreflected(proxy: proxy)
        } label: {
            HStack(spacing: CairnSpacing.size2) {
                Image(systemName: "pencil")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color.cairnAccentInk)
                    .accessibilityHidden(true)
                Text(bannerText)
                    .font(.cairnLabel.weight(.medium))
                    .foregroundStyle(Color.cairnAccentInk)
                Spacer(minLength: 0)
                Image(systemName: "chevron.down")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Color.cairnAccentInk.opacity(0.6))
                    .accessibilityHidden(true)
            }
            .padding(.vertical, CairnSpacing.size3)
            .padding(.horizontal, CairnSpacing.size3)
            .background(Color.cairnSage50)
            .clipShape(RoundedRectangle(cornerRadius: CairnRadii.medium))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityHint("Jumps to the first moment waiting for reflection")
    }

    /// The newest moment still inside the recent window that has no reflection —
    /// the first one the reader meets scrolling down from the top. `nil` when none
    /// is currently paged in (in practice the recent window sits inside the first
    /// page, so this resolves), in which case the banner tap is a no-op.
    private var firstRecentUnreflectedID: UUID? {
        let cutoff = MomentTimelineFetcher.pastWeekCutoff()
        return moments.first { $0.timestamp >= cutoff && isUnreflected($0) }?.id
    }

    private func isUnreflected(_ moment: Moment) -> Bool {
        moment.reflection?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ?? true
    }

    private func scrollToFirstUnreflected(proxy: ScrollViewProxy) {
        guard let targetID = firstRecentUnreflectedID else { return }
        withAnimation {
            proxy.scrollTo(targetID, anchor: .top)
        }
    }

    private var list: some View {
        List {
            ForEach(groupedDays, id: \.self) { day in
                Section {
                    ForEach(grouped[day] ?? [], id: \.id) { moment in
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

    /// Fires on first appear, tab switch back to Path, and every ModelContext.didSave
    /// while Path is visible. Replaces the loaded slice wholesale with a fresh
    /// consistent snapshot from the store — so remote deletes propagate (a stale
    /// merge-and-carry-forward strategy would leave deleted rows on screen), and
    /// future-dated arrivals (device clock skew, imports) still surface (a `.now`
    /// upper bound would drop them into a hole where they contribute to
    /// totalStoreCount but never render).
    private func refreshInitialWindow() async {
        refreshCounts()
        guard !isLoading else { return }

        // First appear: no cursor exists yet. Fetch the newest page unbounded so
        // future-dated moments are included.
        guard let oldestLoaded = moments.last?.timestamp else {
            let fresh = (try? modelContext.fetch(
                MomentTimelineFetcher.descriptorNewestPage(limit: pageSize)
            )) ?? []
            moments = fresh
            hasReachedStart = fresh.count < pageSize
            return
        }

        // Subsequent refreshes: refetch the entire currently-loaded slice as
        // [oldestLoaded, ∞), no time upper bound. Bounded in practice by how far the
        // user has paged back.
        let fresh = (try? modelContext.fetch(
            MomentTimelineFetcher.descriptorNewerThan(oldestLoaded)
        )) ?? []
        moments = fresh
        // If a CloudKit import or another context saved a moment *older* than
        // oldestLoaded while we thought we had reached the start, the reloaded
        // window won't include it — but totalStoreCount will. Clear the flag so
        // the tail sentinel re-arms and loadMore can page the older arrival in.
        // Only downshift: loadMore's own termination rule handles the true end.
        if moments.count < totalStoreCount {
            hasReachedStart = false
        }
    }

    /// Called by the tail sentinel. Fetches the next page of moments strictly older
    /// than the current oldest in `moments`. Cursor-based paging is gap-tolerant: a
    /// user with a long stretch of no captures doesn't get a false "start of your
    /// path" — the fetch just skips the empty stretch and returns older moments.
    ///
    /// Compound `(timestamp, id)` cursor means every page strictly advances the
    /// cursor. No overlap, no dedupe needed, and dense timestamp ties don't strand
    /// history. `hasReachedStart` flips iff the fetch returns fewer than `pageSize`
    /// results — SwiftData's definitive signal there's nothing older.
    private func loadMore() async {
        guard !isLoading, !hasReachedStart else { return }
        guard let last = moments.last else {
            // Nothing loaded yet — refreshInitialWindow will handle this via .onAppear.
            return
        }
        isLoading = true
        defer { isLoading = false }
        let descriptor = MomentTimelineFetcher.descriptorBefore(
            timestamp: last.timestamp,
            id: last.id,
            limit: pageSize
        )
        let fetched = (try? modelContext.fetch(descriptor)) ?? []
        moments.append(contentsOf: fetched)
        if fetched.count < pageSize {
            hasReachedStart = true
        }
    }

    /// Runs the cheap fetch-count queries used by the header, banner, and empty state.
    private func refreshCounts() {
        totalStoreCount = (try? modelContext.fetchCount(FetchDescriptor<Moment>())) ?? 0
        pastWeekCount = (try? modelContext.fetchCount(
            MomentTimelineFetcher.pastWeekCountDescriptor()
        )) ?? 0
        recentUnreflectedCount = (try? modelContext.fetchCount(
            MomentTimelineFetcher.unreflectedRecentCountDescriptor()
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
