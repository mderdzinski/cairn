import Foundation

public struct DailyTotals: Sendable, Hashable {
    public let day: Date
    public let contentment: Int
    public let hindrance: Int

    public init(day: Date, contentment: Int, hindrance: Int) {
        self.day = day
        self.contentment = contentment
        self.hindrance = hindrance
    }

    public var total: Int {
        contentment + hindrance
    }
}

public struct CategoryTotal: Sendable, Hashable {
    public let category: MomentCategory
    public let count: Int

    public init(category: MomentCategory, count: Int) {
        self.category = category
        self.count = count
    }
}

public enum MomentAggregates {
    public static func filter(
        moments: [Moment],
        within range: PatternsRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [Moment] {
        let cutoff = cutoffDate(for: range, now: now, calendar: calendar)
        return moments.filter { $0.timestamp >= cutoff }
    }

    public static func daily(
        moments: [Moment],
        range: PatternsRange,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [DailyTotals] {
        let today = calendar.startOfDay(for: now)
        let days = (0 ..< range.dayCount).compactMap { offset in
            calendar.date(byAdding: .day, value: -offset, to: today)
        }.reversed()

        let buckets = Dictionary(grouping: moments) { moment in
            calendar.startOfDay(for: moment.timestamp)
        }

        return days.map { day in
            let dayMoments = buckets[day] ?? []
            let contentment = dayMoments.lazy.filter(\.category.isContentment).count
            let hindrance = dayMoments.count - contentment
            return DailyTotals(day: day, contentment: contentment, hindrance: hindrance)
        }
    }

    public static func breakdown(moments: [Moment]) -> [CategoryTotal] {
        let counts = Dictionary(grouping: moments, by: \.category)
            .mapValues(\.count)

        var totals: [CategoryTotal] = []
        if let contentment = counts[.contentment], contentment > 0 {
            totals.append(CategoryTotal(category: .contentment, count: contentment))
        }
        let hindrances = MomentCategory.allCases
            .filter { !$0.isContentment }
            .compactMap { category -> CategoryTotal? in
                guard let count = counts[category], count > 0 else { return nil }
                return CategoryTotal(category: category, count: count)
            }
            .sorted { $0.count > $1.count }

        totals.append(contentsOf: hindrances)
        return totals
    }

    public static func contentmentSplit(moments: [Moment]) -> (contentment: Int, friction: Int) {
        let contentment = moments.lazy.filter(\.category.isContentment).count
        return (contentment, moments.count - contentment)
    }

    private static func cutoffDate(
        for range: PatternsRange,
        now: Date,
        calendar: Calendar
    ) -> Date {
        let today = calendar.startOfDay(for: now)
        let offset = -(range.dayCount - 1)
        return calendar.date(byAdding: .day, value: offset, to: today) ?? today
    }
}
