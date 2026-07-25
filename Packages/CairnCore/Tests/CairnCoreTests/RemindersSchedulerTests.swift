@testable import CairnCore
import Foundation
import Testing

private struct FixedRandomSource: RandomNumberGenerator {
    var values: [UInt64]
    var index = 0

    init(_ values: [UInt64]) {
        self.values = values
    }

    mutating func next() -> UInt64 {
        defer { index = (index + 1) % values.count }
        return values[index]
    }
}

@Suite("RemindersScheduler")
struct RemindersSchedulerTests {
    private let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .gmt
        return calendar
    }()

    private var midnight: Date {
        let components = DateComponents(
            year: 2026,
            month: 6,
            day: 22,
            hour: 0,
            minute: 0
        )
        return calendar.date(from: components) ?? Date()
    }

    private func at(_ hour: Int, _ minute: Int = 0) -> Date {
        calendar.date(byAdding: .minute, value: hour * 60 + minute, to: midnight) ?? midnight
    }

    @Test("Empty when both reminders disabled")
    func emptyWhenDisabled() {
        let settings = RemindersSettings()
        var random = FixedRandomSource([42])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: at(6),
            calendar: calendar,
            randomSource: &random
        )
        #expect(result.isEmpty)
    }

    @Test("Notice once-a-day fires exactly once per look-ahead day")
    func noticeOncePerDay() {
        let settings = RemindersSettings(noticeEnabled: true, freq: .once)
        var random = FixedRandomSource([100, 200, 300, 400, 500])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(6),
            calendar: calendar,
            lookAheadDays: 1,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }
        #expect(notices.count == 1)
    }

    @Test("Notice few-a-day caps at 3 per day across the look-ahead")
    func noticeFewPerDayCap() {
        let settings = RemindersSettings(noticeEnabled: true, freq: .few)
        var random = FixedRandomSource([60, 200, 400, 600, 700, 800, 100, 300, 500, 720])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(6),
            calendar: calendar,
            lookAheadDays: 3,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }
        // Three days × three-per-day cap
        #expect(notices.count <= 9)
        let perDay = Dictionary(grouping: notices) { calendar.startOfDay(for: $0.fireDate) }
        for (_, dayFires) in perDay {
            #expect(dayFires.count <= 3)
        }
    }

    @Test("Notice look-ahead covers the full window in days")
    func noticeLookAheadDays() {
        let settings = RemindersSettings(noticeEnabled: true, freq: .once)
        var random = FixedRandomSource(Array(60 ... 200).map { UInt64($0) })
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(6),
            calendar: calendar,
            lookAheadDays: 5,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }
        let distinctDays = Set(notices.map { calendar.startOfDay(for: $0.fireDate) })
        #expect(distinctDays.count == 5)
    }

    @Test("Notice fires are spaced at least 60 minutes apart")
    func noticeSpacing() {
        let settings = RemindersSettings(noticeEnabled: true, freq: .few)
        var random = FixedRandomSource([60, 130, 200, 400, 500, 600, 700, 800, 60, 720])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(6),
            calendar: calendar,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }.sorted { $0.fireDate < $1.fireDate }
        for pair in zip(notices, notices.dropFirst()) {
            let gap = pair.1.fireDate.timeIntervalSince(pair.0.fireDate)
            #expect(gap >= RemindersScheduler.minimumNoticeSpacing)
        }
    }

    @Test("Notice fires never land outside active hours")
    func noticeInsideActiveHours() {
        let settings = RemindersSettings(
            noticeEnabled: true,
            freq: .few,
            activeHoursStart: 9 * 60,
            activeHoursEnd: 17 * 60
        )
        var random = FixedRandomSource([10, 200, 350, 470, 60, 380, 250])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(6),
            calendar: calendar,
            randomSource: &random
        )
        for reminder in result where reminder.kind == .notice {
            let minutes = calendar.component(.hour, from: reminder.fireDate) * 60
                + calendar.component(.minute, from: reminder.fireDate)
            #expect(minutes >= settings.activeHoursStart)
            #expect(minutes < settings.activeHoursEnd)
        }
    }

    @Test("Every fire respects the minimum lead time")
    func minimumLeadTimeInvariant() {
        let settings = RemindersSettings(noticeEnabled: true, reflectEnabled: true, freq: .few)
        var random = FixedRandomSource([60, 200, 400, 600, 800, 100, 300])
        let now = at(6)
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: now,
            calendar: calendar,
            randomSource: &random
        )
        #expect(!result.isEmpty)
        for reminder in result {
            #expect(reminder.fireDate.timeIntervalSince(now) > RemindersScheduler.minimumLeadTime)
        }
    }

    @Test("Notice candidates seconds ahead of now are not scheduled")
    func nearNowCandidatesSkipped() {
        // Window ends 21:00 and now is 20:58 — every remaining day-0 candidate
        // is at most 60s ahead, inside the lead-time buffer. Nothing on day 0.
        let settings = RemindersSettings(noticeEnabled: true, freq: .few)
        var random = FixedRandomSource(Array(0 ... 60).map { UInt64($0) })
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(20, 58),
            calendar: calendar,
            lookAheadDays: 1,
            randomSource: &random
        )
        #expect(result.filter { $0.kind == .notice }.isEmpty)
    }

    @Test("Reflect schedules one fire per look-ahead day when moments are waiting")
    func reflectPerDay() {
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 20 * 60)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: at(10),
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(reflects.count == RemindersScheduler.defaultLookAheadDays)
        let sorted = reflects.sorted { $0.fireDate < $1.fireDate }
        #expect(calendar.component(.day, from: sorted[0].fireDate) == 22)
        for reminder in reflects {
            #expect(calendar.component(.hour, from: reminder.fireDate) == 20)
            #expect(calendar.component(.minute, from: reminder.fireDate) == 0)
        }
        let distinctDays = Set(reflects.map { calendar.startOfDay(for: $0.fireDate) })
        #expect(distinctDays.count == reflects.count)
    }

    @Test("Reflect skips today when its time has already passed")
    func reflectSkipsPassedToday() {
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 20 * 60)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: at(22),
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(reflects.count == RemindersScheduler.defaultLookAheadDays - 1)
        let first = reflects.min { $0.fireDate < $1.fireDate }
        #expect(first.map { calendar.component(.day, from: $0.fireDate) } == 23)
    }

    @Test("Reflect schedules nothing when no moments are waiting")
    func reflectGatedOnWaitingMoments() {
        let settings = RemindersSettings(noticeEnabled: true, reflectEnabled: true, freq: .once)
        var random = FixedRandomSource([100, 200, 300])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(10),
            calendar: calendar,
            randomSource: &random
        )
        #expect(result.filter { $0.kind == .reflect }.isEmpty)
        // Notices are unaffected by the gate.
        #expect(!result.filter { $0.kind == .notice }.isEmpty)
    }

    @Test("Notice fires use the namespaced identifier prefix")
    func noticeIdentifiers() {
        let settings = RemindersSettings(noticeEnabled: true, freq: .few)
        var random = FixedRandomSource([60, 200, 400, 600, 800])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: at(6),
            calendar: calendar,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }
        for reminder in notices {
            #expect(reminder.identifier.hasPrefix(RemindersScheduler.noticeIdentifierPrefix))
        }
    }

    @Test("Reflect fires use distinct namespaced identifiers")
    func reflectIdentifiers() {
        let settings = RemindersSettings(reflectEnabled: true)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: at(10),
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        for reminder in reflects {
            #expect(reminder.identifier.hasPrefix(RemindersScheduler.reflectIdentifierPrefix))
        }
        #expect(Set(reflects.map(\.identifier)).count == reflects.count)
    }
}

// MARK: - DST transitions

/// The main suite pins UTC, where elapsed-minute math and wall-clock math agree.
/// These tests pin a DST-observing zone so a regression back to elapsed-minute
/// arithmetic fails loudly. US 2026 transitions: spring-forward Sunday March 8
/// (2:00 → 3:00), fall-back Sunday November 1.
@Suite("RemindersScheduler DST")
struct RemindersSchedulerDSTTests {
    private func losAngelesCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        return calendar
    }

    private func date(_ components: DateComponents, in calendar: Calendar) throws -> Date {
        try #require(calendar.date(from: components))
    }

    @Test("Reflect keeps its wall-clock hour across spring-forward")
    func reflectSpringForward() throws {
        let calendar = try losAngelesCalendar()
        let now = try date(DateComponents(year: 2026, month: 3, day: 8, hour: 1, minute: 0), in: calendar)
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 20 * 60)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: now,
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(reflects.count == RemindersScheduler.defaultLookAheadDays)
        for reminder in reflects {
            #expect(calendar.component(.hour, from: reminder.fireDate) == 20)
            #expect(calendar.component(.minute, from: reminder.fireDate) == 0)
        }
    }

    @Test("Reflect keeps its wall-clock hour across fall-back")
    func reflectFallBack() throws {
        let calendar = try losAngelesCalendar()
        // 00:30 is before the ambiguous repeated 1:00–2:00 hour.
        let now = try date(DateComponents(year: 2026, month: 11, day: 1, hour: 0, minute: 30), in: calendar)
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 20 * 60)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: now,
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(!reflects.isEmpty)
        for reminder in reflects {
            #expect(calendar.component(.hour, from: reminder.fireDate) == 20)
        }
    }

    @Test("Reflect time inside the spring-forward gap shifts to the first valid instant")
    func reflectInGapShiftsForward() throws {
        let calendar = try losAngelesCalendar()
        let now = try date(DateComponents(year: 2026, month: 3, day: 8, hour: 0, minute: 30), in: calendar)
        // 2:30 doesn't exist on March 8 — .nextTime resolves it to 3:00.
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 2 * 60 + 30)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: true,
            now: now,
            calendar: calendar,
            randomSource: &random
        )
        let sorted = result.filter { $0.kind == .reflect }.sorted { $0.fireDate < $1.fireDate }
        let dayZero = try #require(sorted.first)
        #expect(calendar.component(.day, from: dayZero.fireDate) == 8)
        #expect(calendar.component(.hour, from: dayZero.fireDate) == 3)
        #expect(calendar.component(.minute, from: dayZero.fireDate) == 0)
        let dayOne = try #require(sorted.dropFirst().first)
        #expect(calendar.component(.hour, from: dayOne.fireDate) == 2)
        #expect(calendar.component(.minute, from: dayOne.fireDate) == 30)
    }

    @Test("Notices stay inside active hours across a spring-forward day")
    func noticesInsideActiveHoursAcrossSpringForward() throws {
        let calendar = try losAngelesCalendar()
        let now = try date(DateComponents(year: 2026, month: 3, day: 7, hour: 6, minute: 0), in: calendar)
        let settings = RemindersSettings(
            noticeEnabled: true,
            freq: .few,
            activeHoursStart: 8 * 60,
            activeHoursEnd: 21 * 60
        )
        var random = FixedRandomSource([10, 200, 350, 470, 60, 380, 250, 520, 700])
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: now,
            calendar: calendar,
            lookAheadDays: 3,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }
        #expect(!notices.isEmpty)
        for reminder in notices {
            let minutes = calendar.component(.hour, from: reminder.fireDate) * 60
                + calendar.component(.minute, from: reminder.fireDate)
            #expect(minutes >= settings.activeHoursStart)
            #expect(minutes < settings.activeHoursEnd)
        }
    }

    @Test("An active-hours window swallowed by the spring-forward gap yields no fires that day")
    func windowInsideGapYieldsNothing() throws {
        let calendar = try losAngelesCalendar()
        let now = try date(DateComponents(year: 2026, month: 3, day: 8, hour: 0, minute: 30), in: calendar)
        let settings = RemindersSettings(
            noticeEnabled: true,
            freq: .once,
            activeHoursStart: 2 * 60,
            activeHoursEnd: 3 * 60
        )
        var random = FixedRandomSource(Array(0 ... 59).map { UInt64($0) })
        let result = RemindersScheduler.compute(
            settings: settings,
            hasWaitingMoments: false,
            now: now,
            calendar: calendar,
            lookAheadDays: 1,
            randomSource: &random
        )
        // Every candidate resolves to 3:00, outside [2:00, 3:00) — no valid
        // wall time exists that day.
        #expect(result.filter { $0.kind == .notice }.isEmpty)
    }
}
