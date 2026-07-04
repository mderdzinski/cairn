import Foundation
import SwiftData

/// Factories for the paged Path timeline. Keeps predicate + sort + limit shape in one
/// place so the iOS surface and any future watch history reuse the same fetch shape.
public enum MomentTimelineFetcher {
    /// Safety valve against a single window with pathological volume. Real users won't
    /// hit this; a compromised install or a bad import might.
    public static let pageFetchLimit = 500

    /// Fetch moments with `from <= timestamp < until`, newest first, up to `pageFetchLimit`.
    /// The half-open range is important — chained pages should butt up against each other
    /// without duplicating boundary moments.
    public static func pageDescriptor(from: Date, until: Date) -> FetchDescriptor<Moment> {
        var descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.timestamp >= from && $0.timestamp < until },
            sortBy: [SortDescriptor(\Moment.timestamp, order: .reverse)]
        )
        descriptor.fetchLimit = pageFetchLimit
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

    /// Start-of-day 6 days before `now` — i.e. a 7-day inclusive window. Exposed so
    /// tests can pin the boundary without executing a fetch.
    public static func pastWeekCutoff(now: Date = .now, calendar: Calendar = .current) -> Date {
        let startOfToday = calendar.startOfDay(for: now)
        return calendar.date(byAdding: .day, value: -6, to: startOfToday) ?? startOfToday
    }
}
