import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnWatchApp: App {
    private let sharedModelContainer: ModelContainer = {
        do {
            return try MomentStore.makeContainer(
                cloudKitContainerID: "iCloud.com.markderdzinski.Cairn"
            ).container
        } catch {
            // Both CloudKit and local persistence failed — genuinely unrecoverable.
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
