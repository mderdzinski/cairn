@testable import CairnCore
import Foundation
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
}
