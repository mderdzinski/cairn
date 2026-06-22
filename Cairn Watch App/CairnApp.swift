import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnWatchApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([Moment.self])
        let configuration = ModelConfiguration(
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
            WatchRootView()
        }
        .modelContainer(sharedModelContainer)
    }
}
