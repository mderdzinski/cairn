import Foundation

public enum ReminderKind: String, Sendable, Hashable {
    case notice
    case reflect
}

public struct ScheduledReminder: Sendable, Hashable {
    public let kind: ReminderKind
    public let fireDate: Date
    public let identifier: String

    public init(kind: ReminderKind, fireDate: Date, identifier: String) {
        self.kind = kind
        self.fireDate = fireDate
        self.identifier = identifier
    }
}

public enum RemindersScheduler {
    public static let noticeIdentifierPrefix = "cairn.reminders.notice"
    public static let reflectIdentifier = "cairn.reminders.reflect"

    /// Minimum spacing between two notice fires on the same day.
    public static let minimumNoticeSpacing: TimeInterval = 60 * 60

    public static func compute(
        settings: RemindersSettings,
        now: Date,
        calendar: Calendar = .current,
        randomSource: inout some RandomNumberGenerator
    ) -> [ScheduledReminder] {
        var out: [ScheduledReminder] = []
        if settings.noticeEnabled {
            out.append(contentsOf: noticeFires(
                settings: settings,
                now: now,
                calendar: calendar,
                randomSource: &randomSource
            ))
        }
        if settings.reflectEnabled, let reflectFire = reflectFire(
            settings: settings,
            now: now,
            calendar: calendar
        ) {
            out.append(reflectFire)
        }
        return out
    }

    private static func noticeFires(
        settings: RemindersSettings,
        now: Date,
        calendar: Calendar,
        randomSource: inout some RandomNumberGenerator
    ) -> [ScheduledReminder] {
        let cap = settings.freq.dailyCap
        guard cap > 0,
              settings.activeHoursEnd > settings.activeHoursStart
        else { return [] }

        var fires: [Date] = []
        let attempts = max(cap * 20, 60)

        for _ in 0 ..< attempts where fires.count < cap {
            guard let candidate = randomFire(
                settings: settings,
                referenceDay: now,
                calendar: calendar,
                randomSource: &randomSource
            ),
                candidate > now,
                fires.allSatisfy({ abs($0.timeIntervalSince(candidate)) >= minimumNoticeSpacing })
            else { continue }
            fires.append(candidate)
        }

        if fires.isEmpty, let tomorrowDay = calendar.date(byAdding: .day, value: 1, to: now) {
            for _ in 0 ..< attempts where fires.count < cap {
                guard let candidate = randomFire(
                    settings: settings,
                    referenceDay: tomorrowDay,
                    calendar: calendar,
                    randomSource: &randomSource
                ),
                    candidate > now,
                    fires.allSatisfy({ abs($0.timeIntervalSince(candidate)) >= minimumNoticeSpacing })
                else { continue }
                fires.append(candidate)
            }
        }

        return fires.sorted().enumerated().map { index, date in
            ScheduledReminder(
                kind: .notice,
                fireDate: date,
                identifier: "\(noticeIdentifierPrefix).\(index)"
            )
        }
    }

    private static func randomFire(
        settings: RemindersSettings,
        referenceDay: Date,
        calendar: Calendar,
        randomSource: inout some RandomNumberGenerator
    ) -> Date? {
        let startOfDay = calendar.startOfDay(for: referenceDay)
        let span = settings.activeHoursEnd - settings.activeHoursStart
        guard span > 0 else { return nil }
        let pick = Int.random(in: 0 ..< span, using: &randomSource)
        let minutes = settings.activeHoursStart + pick
        return calendar.date(byAdding: .minute, value: minutes, to: startOfDay)
    }

    private static func reflectFire(
        settings: RemindersSettings,
        now: Date,
        calendar: Calendar
    ) -> ScheduledReminder? {
        let (hour, minute) = RemindersSettings.hourMinute(from: settings.reflectTime)
        let startOfToday = calendar.startOfDay(for: now)
        guard var fire = calendar.date(byAdding: .minute, value: hour * 60 + minute, to: startOfToday) else {
            return nil
        }
        if fire <= now, let tomorrow = calendar.date(byAdding: .day, value: 1, to: fire) {
            fire = tomorrow
        }
        return ScheduledReminder(kind: .reflect, fireDate: fire, identifier: reflectIdentifier)
    }
}
