@testable import CairnCore
import Foundation
import SwiftData
import Testing

@Suite("MomentTimelineFetcher")
struct MomentTimelineFetcherTests {
    @Test("pastWeekCutoff is start-of-day, 6 days before now")
    func pastWeekCutoffBoundary() {
        let calendar = Calendar(identifier: .gregorian)
        // 2026-07-04 10:30 → cutoff should be 2026-06-28 00:00 (a 7-day inclusive window).
        var components = DateComponents(year: 2026, month: 7, day: 4, hour: 10, minute: 30)
        components.calendar = calendar
        let now = calendar.date(from: components) ?? Date()

        let cutoff = MomentTimelineFetcher.pastWeekCutoff(now: now, calendar: calendar)

        var expected = DateComponents(year: 2026, month: 6, day: 28, hour: 0, minute: 0, second: 0)
        expected.calendar = calendar
        let expectedDate = calendar.date(from: expected) ?? Date()
        #expect(cutoff == expectedDate)
    }

    @Test("descriptorBefore uses the caller-supplied limit")
    func descriptorBeforeLimit() {
        let descriptor = MomentTimelineFetcher.descriptorBefore(
            timestamp: .now,
            id: UUID(),
            limit: 25
        )
        #expect(descriptor.fetchLimit == 25)
    }

    @Test("descriptorBefore defaults to the documented page size")
    func descriptorBeforeDefaultLimit() {
        let descriptor = MomentTimelineFetcher.descriptorBefore(
            timestamp: .now,
            id: UUID()
        )
        #expect(descriptor.fetchLimit == MomentTimelineFetcher.defaultPageSize)
        #expect(MomentTimelineFetcher.defaultPageSize == 50)
    }

    @Test("unreflectedCountDescriptor has no fetch limit — it counts the whole store")
    func unreflectedCountDescriptorNoLimit() {
        let descriptor = MomentTimelineFetcher.unreflectedCountDescriptor()
        #expect(descriptor.fetchLimit == nil)
    }

    @Test("descriptorNewestPage uses the caller-supplied limit and no time bound")
    func descriptorNewestPageShape() {
        let descriptor = MomentTimelineFetcher.descriptorNewestPage(limit: 10)
        #expect(descriptor.fetchLimit == 10)
        // No predicate — the fetch is intentionally unbounded in time so future-dated
        // moments still surface.
        #expect(descriptor.predicate == nil)
    }

    @Test("descriptorNewerThan has no fetch limit — it reloads a known window")
    func descriptorNewerThanNoLimit() {
        let descriptor = MomentTimelineFetcher.descriptorNewerThan(.now)
        #expect(descriptor.fetchLimit == nil)
    }

    @Test("todayCountDescriptor counts only moments at or after the start of today")
    func todayCountDescriptorCountsToday() throws {
        let calendar = Calendar(identifier: .gregorian)
        var components = DateComponents(year: 2026, month: 7, day: 4, hour: 10, minute: 30)
        components.calendar = calendar
        let now = calendar.date(from: components) ?? Date()
        let startOfToday = calendar.startOfDay(for: now)

        let container = try ModelContainer(
            for: Moment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        // Two moments earlier today, one just after midnight (still today), and two
        // from previous days that must be excluded.
        context.insert(Moment(timestamp: now))
        context.insert(Moment(timestamp: startOfToday.addingTimeInterval(60)))
        context.insert(Moment(timestamp: startOfToday))
        context.insert(Moment(timestamp: startOfToday.addingTimeInterval(-1)))
        context.insert(Moment(timestamp: startOfToday.addingTimeInterval(-86_400)))

        let count = try context.fetchCount(
            MomentTimelineFetcher.todayCountDescriptor(now: now, calendar: calendar)
        )
        #expect(count == 3)
    }

    @Test("todayCountDescriptor boundary follows now — yesterday's cutoff drops a day")
    func todayCountDescriptorFollowsNow() throws {
        let calendar = Calendar(identifier: .gregorian)
        var yesterdayComponents = DateComponents(year: 2026, month: 7, day: 3, hour: 9)
        yesterdayComponents.calendar = calendar
        let yesterday = calendar.date(from: yesterdayComponents) ?? Date()
        let today = calendar.date(byAdding: .day, value: 1, to: yesterday) ?? Date()

        let container = try ModelContainer(
            for: Moment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        let context = ModelContext(container)
        // A single moment logged yesterday morning.
        context.insert(Moment(timestamp: yesterday))

        // Yesterday's descriptor counts it; today's descriptor — the boundary having
        // rolled forward — must not. This is exactly the watch's midnight-rollover case.
        let countYesterday = try context.fetchCount(
            MomentTimelineFetcher.todayCountDescriptor(now: yesterday, calendar: calendar)
        )
        let countToday = try context.fetchCount(
            MomentTimelineFetcher.todayCountDescriptor(now: today, calendar: calendar)
        )
        #expect(countYesterday == 1)
        #expect(countToday == 0)
    }
}
