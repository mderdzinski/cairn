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

    init() {
        CairnApp.migrateOnboardingFlagForUpgradedInstalls()
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

    private let storeResult: MomentStoreResult = {
        let isUnderXCTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        do {
            return try MomentStore.makeContainer(
                cloudKitContainerID: "iCloud.com.markderdzinski.Cairn",
                inMemory: isUnderXCTest
            )
        } catch {
            // Both CloudKit and local persistence failed — genuinely unrecoverable.
            fatalError("Failed to create Cairn ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView(
                remindersService: appDelegate.remindersService,
                storeBacking: storeResult.backing
            )
            .preferredColorScheme(.light)
        }
        .modelContainer(storeResult.container)
    }
}
