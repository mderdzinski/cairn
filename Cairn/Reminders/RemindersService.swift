import CairnCore
import Foundation
import UserNotifications

@MainActor
@Observable
final class RemindersService: NSObject {
    private let center = UNUserNotificationCenter.current()
    private var rescheduleGeneration: UInt64 = 0
    var lastDeepLinkURL: URL?

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

    func reschedule(settings: RemindersSettings, now: Date = .now) async {
        rescheduleGeneration &+= 1
        let generation = rescheduleGeneration

        await cancelAll()
        // A newer call landed while we awaited cancel — bail before
        // re-adding stale requests on top of the newer batch's work.
        guard generation == rescheduleGeneration else { return }
        guard settings.anyEnabled else { return }

        var random = SystemRandomNumberGenerator()
        let scheduled = RemindersScheduler.compute(
            settings: settings,
            now: now,
            randomSource: &random
        )

        for reminder in scheduled {
            guard generation == rescheduleGeneration else { return }
            let request = makeRequest(reminder: reminder)
            try? await center.add(request)
        }
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
