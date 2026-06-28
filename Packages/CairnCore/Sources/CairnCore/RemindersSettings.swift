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

    /// Schema version of the persisted blob. Bump when adding a field that
    /// requires a migration; defaults to ``currentSchemaVersion`` for fresh installs
    /// and any blob written before versioning landed.
    public var schemaVersion: Int
    public var noticeEnabled: Bool
    public var reflectEnabled: Bool
    public var freq: Frequency
    public var activeHoursStart: Int
    public var activeHoursEnd: Int
    public var reflectTime: Int
    public var hasPrimedPermission: Bool

    public static let storageKey = "cairn.reminders"
    public static let currentSchemaVersion = 1

    public init(
        schemaVersion: Int = RemindersSettings.currentSchemaVersion,
        noticeEnabled: Bool = false,
        reflectEnabled: Bool = false,
        freq: Frequency = .once,
        activeHoursStart: Int = 8 * 60,
        activeHoursEnd: Int = 21 * 60,
        reflectTime: Int = 20 * 60,
        hasPrimedPermission: Bool = false
    ) {
        self.schemaVersion = schemaVersion
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

    /// Decode a settings blob, preserving as many user-configured fields as possible.
    ///
    /// Strict decode succeeds → return as-is.
    /// Strict decode fails but the blob is a JSON object → keep every field that
    /// decodes cleanly, fill the rest from defaults. This prevents a forward-incompatible
    /// or partially corrupted blob from silently wiping a user's whole configuration.
    /// Blob is unreadable JSON → return defaults.
    public static func decode(_ data: Data) -> RemindersSettings {
        if let strict = try? JSONDecoder().decode(RemindersSettings.self, from: data) {
            return strict
        }
        guard
            let raw = try? JSONSerialization.jsonObject(with: data),
            let object = raw as? [String: Any]
        else {
            return RemindersSettings()
        }
        let defaults = RemindersSettings()
        return RemindersSettings(
            schemaVersion: object["schemaVersion"] as? Int ?? defaults.schemaVersion,
            noticeEnabled: object["noticeEnabled"] as? Bool ?? defaults.noticeEnabled,
            reflectEnabled: object["reflectEnabled"] as? Bool ?? defaults.reflectEnabled,
            freq: (object["freq"] as? String).flatMap(Frequency.init(rawValue:)) ?? defaults.freq,
            activeHoursStart: object["activeHoursStart"] as? Int ?? defaults.activeHoursStart,
            activeHoursEnd: object["activeHoursEnd"] as? Int ?? defaults.activeHoursEnd,
            reflectTime: object["reflectTime"] as? Int ?? defaults.reflectTime,
            hasPrimedPermission: object["hasPrimedPermission"] as? Bool ?? defaults.hasPrimedPermission
        )
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
