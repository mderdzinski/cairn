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
            now: at(6),
            calendar: calendar,
            noticeLookAheadDays: 1,
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
            now: at(6),
            calendar: calendar,
            noticeLookAheadDays: 3,
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
            now: at(6),
            calendar: calendar,
            noticeLookAheadDays: 5,
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

    @Test("Reflect fires once today if scheduled time is in the future")
    func reflectToday() {
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 20 * 60)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            now: at(10),
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(reflects.count == 1)
        let fire = reflects[0].fireDate
        let day = calendar.component(.day, from: fire)
        let hour = calendar.component(.hour, from: fire)
        #expect(day == 22)
        #expect(hour == 20)
    }

    @Test("Reflect rolls to tomorrow if scheduled time has already passed today")
    func reflectTomorrow() {
        let settings = RemindersSettings(reflectEnabled: true, reflectTime: 20 * 60)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            now: at(22),
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(reflects.count == 1)
        let fire = reflects[0].fireDate
        let day = calendar.component(.day, from: fire)
        #expect(day == 23)
    }

    @Test("Notice fires use the namespaced identifier prefix")
    func noticeIdentifiers() {
        let settings = RemindersSettings(noticeEnabled: true, freq: .few)
        var random = FixedRandomSource([60, 200, 400, 600, 800])
        let result = RemindersScheduler.compute(
            settings: settings,
            now: at(6),
            calendar: calendar,
            randomSource: &random
        )
        let notices = result.filter { $0.kind == .notice }
        for reminder in notices {
            #expect(reminder.identifier.hasPrefix(RemindersScheduler.noticeIdentifierPrefix))
        }
    }

    @Test("Reflect uses the canonical identifier")
    func reflectIdentifier() {
        let settings = RemindersSettings(reflectEnabled: true)
        var random = FixedRandomSource([0])
        let result = RemindersScheduler.compute(
            settings: settings,
            now: at(10),
            calendar: calendar,
            randomSource: &random
        )
        let reflects = result.filter { $0.kind == .reflect }
        #expect(reflects.first?.identifier == RemindersScheduler.reflectIdentifier)
    }
}
