import Foundation

public struct RemindersSettings: Codable, Sendable, Equatable {
    public enum Frequency: String, Codable, CaseIterable, Sendable {
        case once
        case few

        public var displayName: String {
            switch self {
            case .once: "Once a day"
            case .few: "A few"
            }
        }

        public var dailyCap: Int {
            switch self {
            case .once: 1
            case .few: 3
            }
        }
    }

    public var noticeEnabled: Bool
    public var reflectEnabled: Bool
    public var freq: Frequency
    public var activeHoursStart: Int
    public var activeHoursEnd: Int
    public var reflectTime: Int
    public var hasPrimedPermission: Bool

    public static let storageKey = "cairn.reminders"

    public init(
        noticeEnabled: Bool = false,
        reflectEnabled: Bool = false,
        freq: Frequency = .once,
        activeHoursStart: Int = 8 * 60,
        activeHoursEnd: Int = 21 * 60,
        reflectTime: Int = 20 * 60,
        hasPrimedPermission: Bool = false
    ) {
        self.noticeEnabled = noticeEnabled
        self.reflectEnabled = reflectEnabled
        self.freq = freq
        self.activeHoursStart = activeHoursStart
        self.activeHoursEnd = activeHoursEnd
        self.reflectTime = reflectTime
        self.hasPrimedPermission = hasPrimedPermission
    }

    public static func encode(_ settings: RemindersSettings) -> Data {
        (try? JSONEncoder().encode(settings)) ?? Data()
    }

    public static func decode(_ data: Data) -> RemindersSettings {
        (try? JSONDecoder().decode(RemindersSettings.self, from: data)) ?? RemindersSettings()
    }
}

public extension RemindersSettings {
    var anyEnabled: Bool {
        noticeEnabled || reflectEnabled
    }

    static func minutesSinceMidnight(hour: Int, minute: Int) -> Int {
        hour * 60 + minute
    }

    static func hourMinute(from minutes: Int) -> (hour: Int, minute: Int) {
        let clamped = max(0, min(24 * 60 - 1, minutes))
        return (clamped / 60, clamped % 60)
    }

    static func format(minutes: Int) -> String {
        let (hour, minute) = hourMinute(from: minutes)
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        let date = Calendar.current.date(from: components) ?? Date()
        return date.formatted(date: .omitted, time: .shortened)
    }
}
