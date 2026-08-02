import CairnCore
import CoreData
import Foundation
import os
import SwiftUI

/// What `SyncStatusMonitor` exposes to views. The state is intentionally minimal —
/// the UI only needs to know which glyph to render and what timestamp (if any) to show.
enum SyncStatus: Equatable {
    /// Sync was never attempted — the app fell back to a local-only store. The Path
    /// header should hide the pip entirely; the iCloud-fallback banner already covers
    /// this case at the top of every tab.
    case disabled
    /// Nothing observed yet this session (cold launch, before any CloudKit event fires).
    case idle
    /// A sync event is in flight.
    case syncing
    /// The most recent sync event finished successfully at the given time.
    case synced(since: Date)
    /// The most recent sync event ended with an error.
    case failed(since: Date)
}

/// Subscribes to `NSPersistentCloudKitContainer.eventChangedNotification` and tracks the
/// most recent import / export event so the UI can surface "synced N min ago" without
/// polling. Setup events are ignored — they fire once per launch regardless of whether
/// anything user-meaningful synced, so they make a noisy signal.
@MainActor
@Observable
final class SyncStatusMonitor {
    private let logger = Logger(subsystem: "com.markderdzinski.Cairn", category: "Sync")
    private(set) var status: SyncStatus
    // nonisolated(unsafe) so the nonisolated deinit can cancel them; both are
    // only ever written on the main actor, and deinit runs after the last
    // reference is gone, so there is no concurrent access.
    private nonisolated(unsafe) var observerTask: Task<Void, Never>?
    private nonisolated(unsafe) var syncingWatchdog: Task<Void, Never>?

    /// How long `.syncing` may persist without a terminal event before the
    /// monitor concludes the finish notification was missed (delivered while
    /// suspended, dropped stream) and stops claiming a sync is in flight.
    private static let syncingTimeout: Duration = .seconds(5 * 60)

    init(backing: MomentStoreBacking) {
        switch backing {
        case .cloud:
            status = .idle
        case .local, .inMemory:
            status = .disabled
        }
        guard backing == .cloud else { return }
        startObserving()
    }

    deinit {
        observerTask?.cancel()
        syncingWatchdog?.cancel()
    }

    private func startObserving() {
        observerTask = Task { [weak self] in
            let stream = NotificationCenter.default.notifications(
                named: NSPersistentCloudKitContainer.eventChangedNotification
            )
            for await note in stream {
                guard let self else { return }
                await handle(note)
            }
        }
    }

    private func handle(_ note: Notification) {
        let key = NSPersistentCloudKitContainer.eventNotificationUserInfoKey
        guard let event = note.userInfo?[key] as? NSPersistentCloudKitContainer.Event else { return }

        // Failures escape every other filter — a failed setup event is the first signal
        // CloudKit sync can't run after the container was created, and the user needs
        // to see it.
        if let error = event.error {
            logger.error("CloudKit \(String(describing: event.type)) failed: \(error.localizedDescription)")
            syncingWatchdog?.cancel()
            status = .failed(since: event.endDate ?? .now)
            return
        }
        // Successful setup events fire once per launch regardless of real sync
        // activity. Successful in-flight setup would also mislead users into
        // thinking a fresh capture is uploading when really the container is
        // just booting. Suppress both.
        guard event.type != .setup else { return }

        if event.endDate == nil {
            status = .syncing
            armSyncingWatchdog()
            return
        }
        syncingWatchdog?.cancel()
        status = .synced(since: event.endDate ?? .now)
    }

    /// `.syncing` can only be cleared by another event notification; if the
    /// terminal event is never delivered (app suspended mid-sync), the pip
    /// would claim "Syncing" for the rest of the session. Degrade to `.idle`
    /// after a timeout — a missed notification isn't evidence of failure, and
    /// the pip's contract is silence when nothing is knowable.
    private func armSyncingWatchdog() {
        syncingWatchdog?.cancel()
        syncingWatchdog = Task { [weak self] in
            try? await Task.sleep(for: Self.syncingTimeout)
            guard !Task.isCancelled, let self, status == .syncing else { return }
            status = .idle
        }
    }
}
