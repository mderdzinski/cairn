import CairnCore
import Foundation
import os
import UserNotifications

/// A failure observed while scheduling reminder notifications. Used by
/// ``RemindersView`` to surface a retry affordance instead of silently leaving
/// the user with no reminders.
struct ScheduleFailure: Equatable {
    var failedCount: Int
    var totalCount: Int
}

@MainActor
@Observable
final class RemindersService: NSObject {
    private let center = UNUserNotificationCenter.current()
    private let logger = Logger(subsystem: "com.markderdzinski.Cairn", category: "Reminders")
    private var rescheduleGeneration: UInt64 = 0
    var lastDeepLinkURL: URL?
    /// Non-nil when the most recent ``reschedule(settings:now:)`` call had at least one
    /// notification request fail to register. Cleared by the next successful call.
    var lastScheduleFailure: ScheduleFailure?
    /// The last known iOS notification authorization status. Updated by
    /// ``refreshAuthorizationStatus()``; views observe this to surface a "permission
    /// revoked in Settings" affordance without polling.
    var currentAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        await center.notificationSettings().authorizationStatus
    }

    /// Re-query the system for the current notification authorization and publish the
    /// result on ``currentAuthorizationStatus``. Safe to call from any scenePhase
    /// transition; never triggers the system permission prompt.
    func refreshAuthorizationStatus() async {
        currentAuthorizationStatus = await authorizationStatus()
    }

    func reschedule(settings: RemindersSettings, now: Date = .now) async {
        rescheduleGeneration &+= 1
        let generation = rescheduleGeneration

        await cancelAll()
        // A newer call landed while we awaited cancel — bail before
        // re-adding stale requests on top of the newer batch's work.
        guard generation == rescheduleGeneration else { return }
        guard settings.anyEnabled else {
            lastScheduleFailure = nil
            return
        }

        var random = SystemRandomNumberGenerator()
        let scheduled = RemindersScheduler.compute(
            settings: settings,
            now: now,
            randomSource: &random
        )

        var failedCount = 0
        for reminder in scheduled {
            guard generation == rescheduleGeneration else { return }
            let request = makeRequest(reminder: reminder)
            do {
                try await center.add(request)
            } catch {
                failedCount += 1
                logger.error("Failed to schedule \(reminder.identifier): \(error.localizedDescription)")
            }
        }

        // Only publish the final tally for the latest generation — a newer call
        // that landed mid-loop will own this state when it finishes.
        guard generation == rescheduleGeneration else { return }
        lastScheduleFailure = failedCount > 0
            ? ScheduleFailure(failedCount: failedCount, totalCount: scheduled.count)
            : nil
    }

    func cancelAll() async {
        let identifiers = await pendingCairnIdentifiers()
        center.removePendingNotificationRequests(withIdentifiers: identifiers)
    }

    private func pendingCairnIdentifiers() async -> [String] {
        await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter {
                $0.hasPrefix(RemindersScheduler.noticeIdentifierPrefix)
                    || $0 == RemindersScheduler.reflectIdentifier
            }
    }

    private func makeRequest(reminder: ScheduledReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Cairn"
        switch reminder.kind {
        case .notice:
            content.body = "What are you noticing right now?"
            content.userInfo = ["cairn.deeplink": "cairn://capture"]
        case .reflect:
            // Stable copy across deliveries because the trigger repeats.
            // Counts would otherwise go stale day-to-day.
            content.body = "A quiet moment to revisit your path."
            content.userInfo = ["cairn.deeplink": "cairn://path"]
        }
        content.sound = .default

        let trigger = makeTrigger(for: reminder)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }

    private func makeTrigger(for reminder: ScheduledReminder) -> UNNotificationTrigger {
        let calendar = Calendar.current
        switch reminder.kind {
        case .notice:
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        case .reflect:
            let components = calendar.dateComponents([.hour, .minute], from: reminder.fireDate)
            return UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        }
    }
}

extension RemindersService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Reflect reminders fire daily regardless of pending count — see
        // RemindersView's helper copy. A future PR with a
        // UNNotificationServiceExtension could gate background delivery
        // on the live pending count; until then the trigger is daily and
        // foreground delivery behaves the same.
        completionHandler([.banner, .sound])
    }

    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        if let raw = userInfo["cairn.deeplink"] as? String, let url = URL(string: raw) {
            Task { @MainActor in
                self.lastDeepLinkURL = url
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }
}
