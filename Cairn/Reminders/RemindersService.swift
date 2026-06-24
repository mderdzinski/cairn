import CairnCore
import Foundation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class RemindersService: NSObject {
    private let center = UNUserNotificationCenter.current()
    private weak var modelContainer: ModelContainer?
    var lastDeepLinkURL: URL?

    func attach(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        center.delegate = self
    }

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
        await cancelAll()
        guard settings.anyEnabled else { return }

        var random = SystemRandomNumberGenerator()
        let scheduled = RemindersScheduler.compute(
            settings: settings,
            now: now,
            randomSource: &random
        )

        for reminder in scheduled {
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

    private func pendingReflectionCount() -> Int {
        guard let container = modelContainer else { return 0 }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Moment>()
        guard let moments = try? context.fetch(descriptor) else { return 0 }
        return moments.filter {
            ($0.reflection ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }.count
    }
}

extension RemindersService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        let identifier = notification.request.identifier
        if identifier == RemindersScheduler.reflectIdentifier {
            Task { @MainActor in
                let count = pendingReflectionCount()
                if count == 0 {
                    completionHandler([])
                } else {
                    completionHandler([.banner, .sound])
                }
            }
        } else {
            completionHandler([.banner, .sound])
        }
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
