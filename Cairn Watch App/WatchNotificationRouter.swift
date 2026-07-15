import Foundation
import UserNotifications
import WatchKit

/// Bridges watch notification taps to in-app navigation.
///
/// watchOS delivers a tapped notification through the notification-center
/// delegate — not through `onOpenURL` — so a reminder tapped on the watch
/// never reaches ``WatchRootView``'s deep-link handler on its own. This router
/// is installed as that delegate at launch (see ``WatchAppDelegate``), reads the
/// `cairn.deeplink` payload the phone attaches to each reminder, and republishes
/// it on ``pendingDeepLink`` for the view to consume. Mirrors the phone app's
/// ``RemindersService`` notification handling.
@MainActor
@Observable
final class WatchNotificationRouter: NSObject {
    /// The deep link from the most recently tapped notification, awaiting
    /// consumption by ``WatchRootView``. Set back to `nil` once routed.
    var pendingDeepLink: URL?
}

extension WatchNotificationRouter: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Show forwarded reminders that land while the watch app is foregrounded,
        // matching the phone's presentation behavior.
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
                self.pendingDeepLink = url
                completionHandler()
            }
        } else {
            completionHandler()
        }
    }
}

/// Owns the notification router and installs it as the system notification
/// delegate before any tapped-notification response can be delivered — including
/// the cold-launch case where tapping the reminder is what starts the app.
/// Mirrors the phone app's `CairnAppDelegate`.
@MainActor
final class WatchAppDelegate: NSObject, WKApplicationDelegate {
    let notificationRouter = WatchNotificationRouter()

    func applicationDidFinishLaunching() {
        UNUserNotificationCenter.current().delegate = notificationRouter
    }
}
