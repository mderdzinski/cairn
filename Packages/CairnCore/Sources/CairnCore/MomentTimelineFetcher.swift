import Foundation
import SwiftData

/// Factories for the paged Path timeline. Keeps predicate + sort + limit shape in one
/// place so the iOS surface and any future watch history reuse the same fetch shape.
///
/// Paging uses a **compound cursor** on `(timestamp, id)`, sorted reverse on both.
/// Timestamp alone isn't enough — two moments can share the same instant (rapid
/// captures, bulk import, cross-device sync) and any cursor over just timestamp
/// either strands ties (`< T`) or infinite-loops (`<= T`). Adding the UUID id as a
/// deterministic tiebreaker means every page strictly advances the cursor and every
/// row is eventually reachable, regardless of tie density.
public enum MomentTimelineFetcher {
    /// Default page size. Sized so an active user sees several days per page and a
    /// light user sees weeks; both feel like normal "load more history" scrolling.
    public static let defaultPageSize = 50

    /// Fetch the `limit` most recent moments in the store, newest first. No time
    /// bound, so a moment with a future-dated timestamp (device clock skew, bulk
    /// import) still surfaces. Used for the very first page load when no cursor
    /// exists yet. Secondary sort on `id` gives deterministic ordering across pages.
    public static func descriptorNewestPage(
        limit: Int = defaultPageSize
    ) -> FetchDescriptor<Moment> {
        var descriptor = FetchDescriptor<Moment>(
            sortBy: [
                SortDescriptor(\Moment.timestamp, order: .reverse),
                SortDescriptor(\Moment.id, order: .reverse),
            ]
        )
        descriptor.fetchLimit = limit
        return descriptor
    }

    /// Fetch every moment whose timestamp is at or after `cursor`, newest first, no
    /// limit. Used to reload the currently-loaded window on a `ModelContext.didSave`
    /// notification: replacing the visible slice with a fresh consistent snapshot
    /// picks up remote deletes, updates, and future-dated arrivals in one shot,
    /// where a merge-and-carry-forward strategy would keep stale rows visible.
    public static func descriptorNewerThan(_ cursor: Date) -> FetchDescriptor<Moment> {
        FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp >= cursor },
            sortBy: [
                SortDescriptor(\Moment.timestamp, order: .reverse),
                SortDescriptor(\Moment.id, order: .reverse),
            ]
        )
    }

    /// Fetch the `limit` most recent moments strictly before the compound cursor
    /// `(timestamp, id)`. The predicate is
    /// `timestamp < T || (timestamp == T && id < cursorID)`, sorted reverse on both,
    /// so every page strictly advances the cursor and there is no overlap or
    /// stranding at boundaries — even under dense timestamp ties.
    ///
    /// When the returned array has fewer than `limit` elements, there are no more
    /// moments in the store strictly before the cursor: `hasReachedStart` should
    /// flip on the caller.
    public static func descriptorBefore(
        timestamp: Date,
        id: UUID,
        limit: Int = defaultPageSize
    ) -> FetchDescriptor<Moment> {
        var descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { m in
                m.timestamp < timestamp
                    || (m.timestamp == timestamp && m.id < id)
            },
            sortBy: [
                SortDescriptor(\Moment.timestamp, order: .reverse),
                SortDescriptor(\Moment.id, order: .reverse),
            ]
        )
        descriptor.fetchLimit = limit
        return descriptor
    }

    /// Descriptor that counts moments in the trailing 7 days ending `now`. Passed to
    /// `modelContext.fetchCount(_:)` in the caller — cheaper than filtering the loaded
    /// slice, and honest since "this week" is defined by wall-clock not by what's paged.
    public static func pastWeekCountDescriptor(now: Date = .now) -> FetchDescriptor<Moment> {
        let cutoff = pastWeekCutoff(now: now)
        return FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp >= cutoff }
        )
    }

    /// "Not reflected, within the trailing 7-day window" — shared by the count
    /// and first-match descriptors so the banner's number and its jump target
    /// can never disagree about membership.
    ///
    /// `ReflectSheet.save` trims whitespace-only reflections down to `nil`
    /// before storing, so the two-arm test `reflection == nil || reflection
    /// == ""` covers every "not reflected" case. (SwiftData #Predicate doesn't
    /// reliably lower `.isEmpty` on optional strings, so the two-arm comparison
    /// stays.)
    private static func unreflectedRecentPredicate(cutoff: Date) -> Predicate<Moment> {
        // swiftlint:disable:next empty_string
        #Predicate { ($0.reflection == nil || $0.reflection == "") && $0.timestamp >= cutoff }
    }

    /// Descriptor that counts unreflected moments **within the trailing 7-day
    /// window** — the same `pastWeekCutoff` boundary the "this week" headline uses.
    /// Bounding the "waiting for reflection" prompt to recent moments keeps it a
    /// gentle, self-resolving invitation instead of an ever-growing all-time
    /// backlog: older unreflected moments quietly age out of the count. They stay
    /// reflectable inline (the row still offers "Add a reflection") — they're just
    /// no longer surfaced by the banner, because a weeks-old feeling has gone cold.
    public static func unreflectedRecentCountDescriptor(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> FetchDescriptor<Moment> {
        FetchDescriptor<Moment>(
            predicate: unreflectedRecentPredicate(cutoff: pastWeekCutoff(now: now, calendar: calendar))
        )
    }

    /// The newest unreflected moment inside the trailing 7-day window — the row
    /// the reflection banner promises to jump to. Sorted `(timestamp, id)`
    /// reverse to match the timeline's paging order exactly, so "first fetched"
    /// and "topmost in the list" are the same row even under timestamp ties.
    public static func firstUnreflectedRecentDescriptor(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> FetchDescriptor<Moment> {
        var descriptor = FetchDescriptor<Moment>(
            predicate: unreflectedRecentPredicate(cutoff: pastWeekCutoff(now: now, calendar: calendar)),
            sortBy: [
                SortDescriptor(\Moment.timestamp, order: .reverse),
                SortDescriptor(\Moment.id, order: .reverse),
            ]
        )
        descriptor.fetchLimit = 1
        return descriptor
    }

    /// Timestamp of the newest moment "waiting for reflection" in the banner's
    /// sense, or nil when none is. Drives conditional reflect-reminder
    /// scheduling; the window and reflection semantics must stay identical to
    /// `unreflectedRecentCountDescriptor` so the reminder and the banner never
    /// disagree. The scheduler uses the timestamp — not a boolean — to stop
    /// scheduling fires past the day this moment ages out of the window.
    /// Fails open on a fetch error (returns `now`, as if a moment were just
    /// captured) — a transient store failure should cost at worst a few
    /// unneeded nudges, not silently disable a feature the user enabled.
    public static func newestWaitingMomentTimestamp(
        in context: ModelContext,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> Date? {
        do {
            return try context.fetch(firstUnreflectedRecentDescriptor(now: now, calendar: calendar))
                .first?.timestamp
        } catch {
            return now
        }
    }

    /// Start-of-day 6 days before `now` — i.e. a 7-day inclusive window. Exposed so
    /// tests can pin the boundary without executing a fetch.
    public static func pastWeekCutoff(now: Date = .now, calendar: Calendar = .current) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
    }

    /// Descriptor that counts moments logged today — timestamp at or after the start
    /// of `now`'s calendar day — newest first.
    ///
    /// **This must be rebuilt whenever the day rolls over.** A descriptor captured
    /// once at view-init freezes "today" at that instant; on a long-lived process
    /// (notably the watch app, which stays resident across midnight) that keeps
    /// counting a previous day's moments as "today". Callers pass the current
    /// `now` and re-derive this on foreground and on `.NSCalendarDayChanged`.
    public static func todayCountDescriptor(
        now: Date = .now,
        calendar: Calendar = .current
    ) -> FetchDescriptor<Moment> {
        let startOfToday = calendar.startOfDay(for: now)
        return FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp >= startOfToday },
            sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
        )
    }
}
