import CairnCore
import SwiftData
import SwiftUI
import UIKit
import UserNotifications

@MainActor
final class CairnAppDelegate: NSObject, UIApplicationDelegate {
    let remindersService = RemindersService()

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = remindersService
        return true
    }
}

@main
struct CairnApp: App {
    @UIApplicationDelegateAdaptor(CairnAppDelegate.self) private var appDelegate

    private let storeResult: MomentStoreResult
    @State private var syncMonitor: SyncStatusMonitor

    init() {
        CairnApp.applyUITestLaunchArgumentsIfPresent()
        CairnApp.migrateOnboardingFlagForUpgradedInstalls()
        let isUnderXCTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let isUITestRun = CommandLine.arguments.contains("-cairn.uitest.reset")
            || CommandLine.arguments.contains("-cairn.uitest.seedOnboardingSeen")
        let result: MomentStoreResult
        do {
            result = try MomentStore.makeContainer(
                cloudKitContainerID: "iCloud.com.markderdzinski.Cairn",
                inMemory: isUnderXCTest || isUITestRun
            )
        } catch {
            // Both CloudKit and local persistence failed — genuinely unrecoverable.
            fatalError("Failed to create Cairn ModelContainer: \(error)")
        }
        storeResult = result
        _syncMonitor = State(wrappedValue: SyncStatusMonitor(backing: result.backing))
    }

    /// Test launch arguments — recognized only when present, no-op in normal runs.
    /// Both arguments first wipe the same set of test-owned UserDefaults keys, so
    /// tests behave identically regardless of any developer simulator history.
    /// `-cairn.uitest.reset` leaves it at that (next launch behaves like a fresh
    /// install; onboarding will show). `-cairn.uitest.seedOnboardingSeen` adds
    /// the `cairn.hasSeenOnboarding = true` write on top so a test can skip past
    /// onboarding without inheriting stale reminder settings.
    private static func applyUITestLaunchArgumentsIfPresent() {
        let args = CommandLine.arguments
        let isReset = args.contains("-cairn.uitest.reset")
        let isSeedOnboardingSeen = args.contains("-cairn.uitest.seedOnboardingSeen")
        guard isReset || isSeedOnboardingSeen else { return }

        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "cairn.hasSeenOnboarding")
        defaults.removeObject(forKey: "cairn.iCloudFallbackBannerDismissed")
        defaults.removeObject(forKey: RemindersSettings.storageKey)

        if isSeedOnboardingSeen {
            defaults.set(true, forKey: "cairn.hasSeenOnboarding")
        }
    }

    /// Pre-render migration so users who already configured reminders on a prior
    /// build don't see the new onboarding flow and have their preferences overwritten
    /// by its defaults. Runs before any view body so there's no one-frame flash of the
    /// onboarding cover. Idempotent: once `cairn.hasSeenOnboarding` is true, this no-ops.
    private static func migrateOnboardingFlagForUpgradedInstalls() {
        let defaults = UserDefaults.standard
        guard !defaults.bool(forKey: "cairn.hasSeenOnboarding") else { return }
        guard let raw = defaults.data(forKey: RemindersSettings.storageKey) else { return }
        let settings = RemindersSettings.decode(raw)
        if settings.anyEnabled || settings.hasPrimedPermission {
            defaults.set(true, forKey: "cairn.hasSeenOnboarding")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootTabView(
                remindersService: appDelegate.remindersService,
                storeBacking: storeResult.backing
            )
            .environment(syncMonitor)
            .preferredColorScheme(.light)
        }
        .modelContainer(storeResult.container)
    }
}
