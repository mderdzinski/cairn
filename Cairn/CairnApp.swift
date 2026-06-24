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

    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([Moment.self])
        let isUnderXCTest = ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil
        let configuration =
            isUnderXCTest
                ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                : ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .private("iCloud.com.markderdzinski.Cairn")
                )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create Cairn ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView(remindersService: appDelegate.remindersService)
                .task {
                    migrateSluggishnessToHeaviness()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func migrateSluggishnessToHeaviness() {
        let context = ModelContext(sharedModelContainer)
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.categoryRaw == "sluggishness" }
        )
        guard let stale = try? context.fetch(descriptor), !stale.isEmpty else { return }
        for moment in stale {
            moment.categoryRaw = MomentCategory.heaviness.rawValue
        }
        try? context.save()
    }
}
