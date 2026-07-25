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
    /// FIFO chain over every notification-center mutation. Each queued block
    /// awaits its predecessor before touching the center, so a full
    /// cancel + compute + add cycle is atomic per call: a stale cancel can
    /// never resume in the middle of a newer call's adds, and a newer call's
    /// pending-requests snapshot always includes every earlier in-flight add.
    private var pipeline: Task<Void, Never>?
    /// Start-of-day of the last reschedule that ran to completion. Gates the
    /// foreground top-up to once per calendar day — the scheduler is
    /// delivery-unaware, so re-rolling candidates more often risks a second
    /// same-day notice after one has already fired.
    private var lastRescheduleDay: Date?
    var lastDeepLinkURL: URL?
    /// Non-nil when the most recent reschedule had at least one notification
    /// request fail to register. Cleared by the next successful call.
    var lastScheduleFailure: ScheduleFailure?
    /// The `waitingMomentTimestamp` the most recently completed reschedule
    /// used. The data-change hook compares against this so only saves that
    /// move the newest waiting moment trigger a reschedule.
    private(set) var lastScheduledWaitingTimestamp: Date?
    /// The last known iOS notification authorization status. Updated by
    /// ``refreshAuthorizationStatus()``; views observe this to surface a "permission
    /// revoked in Settings" affordance without polling.
    var currentAuthorizationStatus: UNAuthorizationStatus = .notDetermined

    func requestAuthorization() async -> Bool {
        let granted: Bool
        do {
            granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            granted = false
        }
        // Publish the outcome immediately — views and the didSave scheduling
        // hook gate on the cached status, and waiting for the next scene
        // activation to refresh it would leave a fresh grant invisible (the
        // first capture after onboarding would silently skip scheduling).
        await refreshAuthorizationStatus()
        return granted
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

    func reschedule(
        settings: RemindersSettings,
        waitingMomentTimestamp: Date?,
        scope: RemindersScheduler.Scope = .all,
        now: Date = .now
    ) async {
        rescheduleGeneration &+= 1
        let generation = rescheduleGeneration
        let previous = pipeline
        let task = Task { [weak self] in
            await previous?.value
            await self?.performReschedule(
                settings: settings,
                waitingMomentTimestamp: waitingMomentTimestamp,
                scope: scope,
                now: now,
                generation: generation
            )
        }
        pipeline = task
        await task.value
    }

    /// Top up the fire horizon at most once per calendar day, preserving
    /// today's pending notices. Yesterday's batch always covered today, so
    /// today's notices are either still pending (kept as-is) or already fired
    /// (and nothing new is added for today) — either way a rebuild can't
    /// produce a second same-day notice. Settings edits call ``reschedule``
    /// with the full scope instead: the user changed the rules, so a full
    /// re-roll is the expected outcome.
    func rescheduleIfStale(settings: RemindersSettings, waitingMomentTimestamp: Date?, now: Date = .now) async {
        guard lastRescheduleDay != Calendar.current.startOfDay(for: now) else { return }
        await reschedule(
            settings: settings,
            waitingMomentTimestamp: waitingMomentTimestamp,
            scope: .futureNoticesAndReflect,
            now: now
        )
    }

    func cancelAll() async {
        // Joins the same FIFO chain as reschedules: a direct cancel (permission
        // revoked) must not interleave with a queued reschedule's add loop.
        rescheduleGeneration &+= 1
        let previous = pipeline
        let task = Task { [weak self] in
            await previous?.value
            await self?.performCancelAll()
        }
        pipeline = task
        await task.value
    }

    private func performReschedule(
        settings: RemindersSettings,
        waitingMomentTimestamp: Date?,
        scope: RemindersScheduler.Scope,
        now: Date,
        generation: UInt64
    ) async {
        // Superseded while queued — the newest queued call redoes cancel+add
        // from scratch, so skip the redundant churn entirely. Execution is
        // strictly serial past this point; no further generation checks needed.
        guard generation == rescheduleGeneration else { return }

        // Must be the raw body, not cancelAll() — enqueueing from inside the
        // chain and awaiting it would deadlock behind this very block.
        await performCancel(scope: scope, now: now)
        guard settings.anyEnabled else {
            lastScheduleFailure = nil
            return
        }

        var random = SystemRandomNumberGenerator()
        let scheduled = RemindersScheduler.compute(
            settings: settings,
            waitingMomentTimestamp: waitingMomentTimestamp,
            now: now,
            scope: scope,
            randomSource: &random
        )

        var failedCount = 0
        for reminder in scheduled {
            let request = makeRequest(reminder: reminder)
            do {
                try await center.add(request)
            } catch {
                failedCount += 1
                logger.error("Failed to schedule \(reminder.identifier): \(error.localizedDescription)")
            }
        }

        lastScheduleFailure = failedCount > 0
            ? ScheduleFailure(failedCount: failedCount, totalCount: scheduled.count)
            : nil
        lastScheduledWaitingTimestamp = waitingMomentTimestamp
        // Reflect-only reschedules don't refresh the notice horizon, so they
        // must not satisfy the daily top-up gate — a midnight capture would
        // otherwise suppress that day's notice top-up.
        if scope != .reflectOnly {
            lastRescheduleDay = Calendar.current.startOfDay(for: .now)
        }
    }

    private func performCancelAll() async {
        await performCancel(scope: .all, now: .now)
    }

    /// Remove exactly the pending requests the paired compute scope will
    /// regenerate — nothing more. In particular, `.futureNoticesAndReflect`
    /// leaves today's day-keyed notices in place so a top-up can never re-roll
    /// a notice for a day whose fire may already have been delivered.
    private func performCancel(scope: RemindersScheduler.Scope, now: Date) async {
        let pending = await center.pendingNotificationRequests().map(\.identifier)
        let toRemove: [String]
        switch scope {
        case .all:
            toRemove = pending.filter { isCairnIdentifier($0) }
        case .reflectOnly:
            toRemove = pending.filter { $0.hasPrefix(RemindersScheduler.reflectIdentifierPrefix) }
        case .futureNoticesAndReflect:
            let today = RemindersScheduler.dayKey(for: now, calendar: Calendar.current)
            toRemove = pending.filter { identifier in
                guard isCairnIdentifier(identifier) else { return false }
                // Keep only today's day-keyed notices; legacy batch-indexed
                // identifiers parse to nil and are swept as stale.
                return RemindersScheduler.noticeIdentifierDayKey(identifier) != today
            }
        }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }

    private func isCairnIdentifier(_ identifier: String) -> Bool {
        // Prefix matching on reflect also sweeps the bare legacy identifier
        // the pre-conditional repeating request used.
        identifier.hasPrefix(RemindersScheduler.noticeIdentifierPrefix)
            || identifier.hasPrefix(RemindersScheduler.reflectIdentifierPrefix)
    }

    private func makeRequest(reminder: ScheduledReminder) -> UNNotificationRequest {
        let content = UNMutableNotificationContent()
        content.title = "Cairn"
        switch reminder.kind {
        case .notice:
            content.body = "What are you noticing right now?"
            content.userInfo = ["cairn.deeplink": "cairn://capture"]
        case .reflect:
            content.body = "A quiet moment to revisit your path."
            content.userInfo = ["cairn.deeplink": "cairn://path"]
        }
        content.sound = .default

        // Both kinds are non-repeating full-date triggers. Reflect fires are
        // scheduled per look-ahead day and gated on moments actually waiting —
        // a local notification can't be suppressed at delivery time, so the
        // "only when moments are waiting" promise is kept at scheduling time.
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: reminder.fireDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger)
    }
}

extension RemindersService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
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
