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
    /// Reflect identifiers are `"\(reflectIdentifierPrefix).\(index)"`, one per
    /// look-ahead day. The prefix value deliberately equals the bare identifier
    /// the pre-1.0.1 repeating reflect request used, so a prefix match sweeps the
    /// legacy request on the first cancel after update — migration for free.
    public static let reflectIdentifierPrefix = "cairn.reminders.reflect"

    /// Minimum spacing between two notice fires on the same day.
    public static let minimumNoticeSpacing: TimeInterval = 60 * 60

    /// Minimum lead time between `now` and any scheduled fire. Candidates are
    /// whole minutes; one that's only seconds ahead can have its minute boundary
    /// pass before the async notification-center add completes, in which case the
    /// calendar trigger never matches and the fire is silently lost.
    public static let minimumLeadTime: TimeInterval = 120

    /// Default look-ahead window for reminder fires. Schedules this many
    /// days of fires up-front so the user can go ~a week without opening the
    /// app and still receive reminders.
    public static let defaultLookAheadDays = 7

    public static func compute(
        settings: RemindersSettings,
        hasWaitingMoments: Bool,
        now: Date,
        calendar: Calendar = .current,
        lookAheadDays: Int = defaultLookAheadDays,
        randomSource: inout some RandomNumberGenerator
    ) -> [ScheduledReminder] {
        var out: [ScheduledReminder] = []
        if settings.noticeEnabled {
            out.append(contentsOf: noticeFires(
                settings: settings,
                now: now,
                calendar: calendar,
                lookAheadDays: lookAheadDays,
                randomSource: &randomSource
            ))
        }
        // Reflect fires are gated on there being something to reflect on —
        // "Only when moments are waiting" is a scheduling-time promise, since a
        // local notification can't be suppressed at delivery time.
        if settings.reflectEnabled, hasWaitingMoments {
            out.append(contentsOf: reflectFires(
                settings: settings,
                now: now,
                calendar: calendar,
                lookAheadDays: lookAheadDays
            ))
        }
        return out
    }

    private struct NoticeContext {
        let settings: RemindersSettings
        let now: Date
        let calendar: Calendar
    }

    private static func noticeFires(
        settings: RemindersSettings,
        now: Date,
        calendar: Calendar,
        lookAheadDays: Int,
        randomSource: inout some RandomNumberGenerator
    ) -> [ScheduledReminder] {
        let cap = settings.freq.dailyCap
        guard cap > 0,
              settings.activeHoursEnd > settings.activeHoursStart,
              lookAheadDays > 0
        else { return [] }

        let context = NoticeContext(settings: settings, now: now, calendar: calendar)
        var fires: [Date] = []
        for dayOffset in 0 ..< lookAheadDays {
            guard let referenceDay = calendar.date(byAdding: .day, value: dayOffset, to: now) else {
                continue
            }
            fires.append(contentsOf: noticeFires(
                forDay: referenceDay,
                cap: cap,
                context: context,
                randomSource: &randomSource
            ))
        }

        return fires.sorted().enumerated().map { index, date in
            ScheduledReminder(
                kind: .notice,
                fireDate: date,
                identifier: "\(noticeIdentifierPrefix).\(index)"
            )
        }
    }

    private static func noticeFires(
        forDay referenceDay: Date,
        cap: Int,
        context: NoticeContext,
        randomSource: inout some RandomNumberGenerator
    ) -> [Date] {
        var dayFires: [Date] = []
        let attempts = max(cap * 20, 60)
        for _ in 0 ..< attempts where dayFires.count < cap {
            guard let candidate = randomFire(
                settings: context.settings,
                referenceDay: referenceDay,
                calendar: context.calendar,
                randomSource: &randomSource
            ),
                candidate > context.now.addingTimeInterval(minimumLeadTime),
                dayFires.allSatisfy({ abs($0.timeIntervalSince(candidate)) >= minimumNoticeSpacing })
            else { continue }
            dayFires.append(candidate)
        }
        return dayFires
    }

    private static func randomFire(
        settings: RemindersSettings,
        referenceDay: Date,
        calendar: Calendar,
        randomSource: inout some RandomNumberGenerator
    ) -> Date? {
        let span = settings.activeHoursEnd - settings.activeHoursStart
        guard span > 0 else { return nil }
        let pick = Int.random(in: 0 ..< span, using: &randomSource)
        let minutes = settings.activeHoursStart + pick
        guard let candidate = wallClockDate(minutes: minutes, on: referenceDay, calendar: calendar),
              isWithinActiveHours(candidate, settings: settings, calendar: calendar)
        else { return nil }
        return candidate
    }

    private static func reflectFires(
        settings: RemindersSettings,
        now: Date,
        calendar: Calendar,
        lookAheadDays: Int
    ) -> [ScheduledReminder] {
        var fires: [Date] = []
        for dayOffset in 0 ..< lookAheadDays {
            guard let referenceDay = calendar.date(byAdding: .day, value: dayOffset, to: now),
                  let fire = wallClockDate(minutes: settings.reflectTime, on: referenceDay, calendar: calendar),
                  fire > now.addingTimeInterval(minimumLeadTime)
            else { continue }
            fires.append(fire)
        }
        return fires.sorted().enumerated().map { index, date in
            ScheduledReminder(
                kind: .reflect,
                fireDate: date,
                identifier: "\(reflectIdentifierPrefix).\(index)"
            )
        }
    }

    /// Resolve minutes-since-midnight to a wall-clock instant on `day`.
    ///
    /// Setting hour/minute components — rather than adding elapsed minutes to
    /// `startOfDay` — is what keeps fires at the user's chosen wall-clock time
    /// across DST transitions (a 23- or 25-hour day makes elapsed-minute math
    /// land an hour off). A time that doesn't exist on `day` (inside the
    /// spring-forward gap) resolves forward to the first valid instant, matching
    /// the iOS alarm convention: slightly late beats never.
    private static func wallClockDate(minutes: Int, on day: Date, calendar: Calendar) -> Date? {
        let (hour, minute) = RemindersSettings.hourMinute(from: minutes)
        return calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day)
    }

    /// A gap-shifted candidate can resolve past the active window (e.g. a window
    /// that sits entirely inside the spring-forward gap); re-validate in
    /// wall-clock space so the "never outside active hours" invariant holds.
    private static func isWithinActiveHours(
        _ date: Date,
        settings: RemindersSettings,
        calendar: Calendar
    ) -> Bool {
        let minutes = calendar.component(.hour, from: date) * 60
            + calendar.component(.minute, from: date)
        return minutes >= settings.activeHoursStart && minutes < settings.activeHoursEnd
    }
}
