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

    @Test("pageDescriptor fetch limit matches the documented ceiling")
    func pageDescriptorLimit() {
        let descriptor = MomentTimelineFetcher.pageDescriptor(from: .distantPast, until: .distantFuture)
        #expect(descriptor.fetchLimit == MomentTimelineFetcher.pageFetchLimit)
        #expect(MomentTimelineFetcher.pageFetchLimit == 500)
    }
}
