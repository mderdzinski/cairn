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
        }
        .modelContainer(storeResult.container)
    }
}
