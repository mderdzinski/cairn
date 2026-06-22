@testable import CairnCore
import Foundation
import Testing

@Suite("MomentAggregates")
struct MomentAggregatesTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_750_000_000) // Sun Jun 15 2025 ~22:26 UTC

    private func moment(_ category: MomentCategory, daysAgo: Int, hourOffset: Int = 12) -> Moment {
        let today = calendar.startOfDay(for: now)
        guard let day = calendar.date(byAdding: .day, value: -daysAgo, to: today),
              let stamp = calendar.date(byAdding: .hour, value: hourOffset, to: day)
        else {
            return Moment(timestamp: now, category: category)
        }
        return Moment(timestamp: stamp, category: category)
    }

    @Test("daily() returns exactly range.dayCount entries for week")
    func dailyWeekCount() {
        let moments = [moment(.contentment, daysAgo: 0)]
        let daily = MomentAggregates.daily(
            moments: moments,
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(daily.count == 7)
    }

    @Test("daily() returns exactly range.dayCount entries for month")
    func dailyMonthCount() {
        let daily = MomentAggregates.daily(
            moments: [],
            range: .month,
            now: now,
            calendar: calendar
        )
        #expect(daily.count == 30)
    }

    @Test("daily() zero-pads empty days")
    func dailyZeroPads() {
        let daily = MomentAggregates.daily(
            moments: [],
            range: .week,
            now: now,
            calendar: calendar
        )
        #expect(daily.allSatisfy { $0.total == 0 })
    }

    @Test("daily() is oldest-first")
    func dailyOldestFirst() {
        let daily = MomentAggregates.daily(
            moments: [],
            range: .week,
            now: now,
            calendar: calendar
        )
        let days = daily.map(\.day)
        #expect(days == days.sorted())
    }

    @Test("daily() bucketizes correctly into contentment/hindrance")
    func dailyBuckets() {
        let moments = [
            moment(.contentment, daysAgo: 0),
            moment(.contentment, daysAgo: 0),
            moment(.aversion, daysAgo: 0),
            moment(.desire, daysAgo: 1),
        ]
        let daily = MomentAggregates.daily(
            moments: moments,
            range: .week,
            now: now,
            calendar: calendar
        )
        let today = daily.last
        #expect(today?.contentment == 2)
        #expect(today?.hindrance == 1)
        let yesterday = daily[daily.count - 2]
        #expect(yesterday.contentment == 0)
        #expect(yesterday.hindrance == 1)
    }

    @Test("breakdown() puts contentment first, hindrances sorted by count")
    func breakdownOrdering() {
        let moments = [
            moment(.contentment, daysAgo: 0),
            moment(.desire, daysAgo: 0),
            moment(.desire, daysAgo: 1),
            moment(.aversion, daysAgo: 0),
            moment(.aversion, daysAgo: 1),
            moment(.aversion, daysAgo: 2),
        ]
        let breakdown = MomentAggregates.breakdown(moments: moments)
        #expect(breakdown.map(\.category) == [.contentment, .aversion, .desire])
        #expect(breakdown[1].count == 3)
        #expect(breakdown[2].count == 2)
    }

    @Test("breakdown() omits categories with zero moments")
    func breakdownOmitsZeros() {
        let moments = [moment(.contentment, daysAgo: 0)]
        let breakdown = MomentAggregates.breakdown(moments: moments)
        #expect(breakdown.map(\.category) == [.contentment])
    }

    @Test("contentmentSplit() splits correctly")
    func split() {
        let moments = [
            moment(.contentment, daysAgo: 0),
            moment(.contentment, daysAgo: 0),
            moment(.aversion, daysAgo: 0),
        ]
        let result = MomentAggregates.contentmentSplit(moments: moments)
        #expect(result.contentment == 2)
        #expect(result.friction == 1)
    }

    @Test("filter() excludes moments older than the week range")
    func filterWeek() {
        let moments = [
            moment(.contentment, daysAgo: 0),
            moment(.contentment, daysAgo: 6),
            moment(.contentment, daysAgo: 7),
            moment(.contentment, daysAgo: 30),
        ]
        let filtered = MomentAggregates.filter(
            moments: moments,
            within: .week,
            now: now,
            calendar: calendar
        )
        #expect(filtered.count == 2)
    }

    @Test("filter() excludes moments older than the month range")
    func filterMonth() {
        let moments = [
            moment(.contentment, daysAgo: 0),
            moment(.contentment, daysAgo: 29),
            moment(.contentment, daysAgo: 30),
        ]
        let filtered = MomentAggregates.filter(
            moments: moments,
            within: .month,
            now: now,
            calendar: calendar
        )
        #expect(filtered.count == 2)
    }
}
