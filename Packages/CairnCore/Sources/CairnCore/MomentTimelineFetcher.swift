import Foundation
import SwiftData

/// Factories for the paged Path timeline. Keeps predicate + sort + limit shape in one
/// place so the iOS surface and any future watch history reuse the same fetch shape.
///
/// Paging is cursor-based (`timestamp < cursor` with a fixed page size) rather than
/// window-based. That way a user with a large gap in their capture history — say
/// nothing between January and July — doesn't hit a false "start of your path" when
/// the pager sweeps across the empty stretch. Every fetch either returns more moments
/// or definitively signals the start.
public enum MomentTimelineFetcher {
    /// Default page size for cursor-based fetches. Sized so an active user sees
    /// several days per page and a light user sees weeks; both feel like normal
    /// "load more history" scrolling.
    public static let defaultPageSize = 50

    /// Fetch the `limit` most recent moments at or before `cursor`, newest first.
    /// Caller uses `moments.last?.timestamp` as the cursor for the next page and
    /// **must dedupe by id** because the predicate is inclusive on the boundary:
    /// two moments sharing the cursor timestamp would otherwise slip through the
    /// crack of a strict `<` cursor. In the common no-tie case, the overlap is at
    /// most one row.
    ///
    /// When the returned array has fewer than `limit` elements, there are no more
    /// moments in the store at or before the cursor.
    public static func descriptorBefore(
        _ cursor: Date,
        limit: Int = defaultPageSize
    ) -> FetchDescriptor<Moment> {
        var descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp <= cursor },
            sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
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

    /// Descriptor that counts moments with no reflection. Passed to
    /// `modelContext.fetchCount(_:)` so the "N moments waiting for reflection"
    /// banner reflects the entire store, not just what's paginated into memory —
    /// otherwise a user with older unreflected moments would see an undercount
    /// (or no banner at all) until they scrolled far enough to load them.
    ///
    /// `ReflectSheet.save` already trims whitespace-only reflections down to
    /// `nil` before storing, so the two-arm predicate `reflection == nil ||
    /// reflection == ""` covers every "not reflected" case.
    public static func unreflectedCountDescriptor() -> FetchDescriptor<Moment> {
        FetchDescriptor<Moment>(
            // SwiftData #Predicate doesn't reliably lower `.isEmpty` on optional
            // strings, so the two-arm comparison stays.
            // swiftlint:disable:next empty_string
            predicate: #Predicate { $0.reflection == nil || $0.reflection == "" }
        )
    }

    /// Start-of-day 6 days before `now` — i.e. a 7-day inclusive window. Exposed so
    /// tests can pin the boundary without executing a fetch.
    public static func pastWeekCutoff(now: Date = .now, calendar: Calendar = .current) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
    }
}
