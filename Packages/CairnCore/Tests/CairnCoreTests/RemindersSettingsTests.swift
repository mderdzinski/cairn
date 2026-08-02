@testable import CairnCore
import Foundation
import Testing

@Suite("RemindersSettings")
struct RemindersSettingsTests {
    @Test("encode/decode roundtrip preserves every field")
    func roundtrip() {
        let original = RemindersSettings(
            noticeEnabled: true,
            reflectEnabled: true,
            freq: .few,
            activeHoursStart: 9 * 60 + 30,
            activeHoursEnd: 22 * 60,
            reflectTime: 19 * 60 + 15,
            hasPrimedPermission: true
        )
        let decoded = RemindersSettings.decode(RemindersSettings.encode(original))
        #expect(decoded == original)
    }

    @Test("decoding a pre-versioning blob preserves user fields")
    func preVersioningBlob() throws {
        // Blob shape from before schemaVersion was added — every field present, no version key.
        let json = """
        {
          "noticeEnabled": true,
          "reflectEnabled": true,
          "freq": "few",
          "activeHoursStart": 540,
          "activeHoursEnd": 1320,
          "reflectTime": 1155,
          "hasPrimedPermission": true
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)

        #expect(decoded.noticeEnabled == true)
        #expect(decoded.reflectEnabled == true)
        #expect(decoded.freq == .few)
        #expect(decoded.activeHoursStart == 540)
        #expect(decoded.activeHoursEnd == 1320)
        #expect(decoded.reflectTime == 1155)
        #expect(decoded.hasPrimedPermission == true)
        #expect(decoded.schemaVersion == RemindersSettings.currentSchemaVersion)
    }

    @Test("decoding a blob with an unknown future field preserves known fields")
    func forwardCompatibleBlob() throws {
        let json = """
        {
          "schemaVersion": 2,
          "noticeEnabled": true,
          "reflectEnabled": false,
          "freq": "once",
          "activeHoursStart": 480,
          "activeHoursEnd": 1260,
          "reflectTime": 1200,
          "hasPrimedPermission": true,
          "futureKnob": "tbd"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)

        #expect(decoded.noticeEnabled == true)
        #expect(decoded.hasPrimedPermission == true)
        #expect(decoded.freq == .once)
        #expect(decoded.schemaVersion == 2)
    }

    @Test("decoding a partially corrupted blob keeps the good fields, not all defaults")
    func partiallyCorruptedBlob() throws {
        // `freq` is the wrong type — strict decode fails. Defensive path should keep the rest.
        let json = """
        {
          "noticeEnabled": true,
          "reflectEnabled": true,
          "freq": 42,
          "activeHoursStart": 600,
          "activeHoursEnd": 1320,
          "reflectTime": 1140,
          "hasPrimedPermission": true
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)

        // User-configured fields survive...
        #expect(decoded.noticeEnabled == true)
        #expect(decoded.reflectEnabled == true)
        #expect(decoded.activeHoursStart == 600)
        #expect(decoded.activeHoursEnd == 1320)
        #expect(decoded.reflectTime == 1140)
        #expect(decoded.hasPrimedPermission == true)
        // ...the bad field falls back to default.
        #expect(decoded.freq == .once)
    }

    @Test("decoding a missing field uses its default without wiping the rest")
    func missingFieldBlob() throws {
        let json = """
        {
          "noticeEnabled": true,
          "freq": "few"
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)

        #expect(decoded.noticeEnabled == true)
        #expect(decoded.freq == .few)
        // Missing fields fall back to defaults rather than failing the whole decode.
        let defaults = RemindersSettings()
        #expect(decoded.reflectEnabled == defaults.reflectEnabled)
        #expect(decoded.activeHoursStart == defaults.activeHoursStart)
        #expect(decoded.reflectTime == defaults.reflectTime)
    }

    @Test("decoding non-JSON data returns defaults")
    func garbageData() {
        let garbage = Data([0xFF, 0xD8, 0xFF, 0xE0])
        let decoded = RemindersSettings.decode(garbage)
        #expect(decoded == RemindersSettings())
    }

    @Test("decoding empty data returns defaults")
    func emptyData() {
        let decoded = RemindersSettings.decode(Data())
        #expect(decoded == RemindersSettings())
    }

    @Test("strict-path decode clamps out-of-range time fields")
    func strictPathClampsOutOfRange() throws {
        // Valid JSON, absurd value — the strict decoder accepts it as readily
        // as the lenient path, so sanitization must cover both.
        let json = """
        {
          "schemaVersion": 1,
          "noticeEnabled": false,
          "reflectEnabled": true,
          "freq": "once",
          "activeHoursStart": 480,
          "activeHoursEnd": 1260,
          "reflectTime": 99999,
          "hasPrimedPermission": false
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)
        #expect(decoded.reflectTime == 24 * 60 - 1)
        #expect(decoded.activeHoursStart == 480)
        #expect(decoded.activeHoursEnd == 1260)
    }

    @Test("an inverted active-hours window falls back to the default window")
    func invertedWindowFallsBackToDefaults() throws {
        let json = """
        {
          "noticeEnabled": true,
          "freq": "few",
          "activeHoursStart": 1200,
          "activeHoursEnd": 600
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)
        let defaults = RemindersSettings()
        #expect(decoded.activeHoursStart == defaults.activeHoursStart)
        #expect(decoded.activeHoursEnd == defaults.activeHoursEnd)
        // Non-window fields untouched.
        #expect(decoded.noticeEnabled == true)
        #expect(decoded.freq == .few)
    }

    @Test("a negative start clamps to zero without resetting a valid window")
    func negativeStartClampsWithoutFallback() throws {
        let json = """
        {
          "activeHoursStart": -5,
          "activeHoursEnd": 600
        }
        """
        let data = try #require(json.data(using: .utf8))
        let decoded = RemindersSettings.decode(data)
        #expect(decoded.activeHoursStart == 0)
        #expect(decoded.activeHoursEnd == 600)
    }
}
