import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnWatchApp: App {
    private let storeResult: MomentStoreResult = {
        do {
            return try MomentStore.makeContainer(
                cloudKitContainerID: "iCloud.com.markderdzinski.Cairn"
            )
        } catch {
            // Both CloudKit and local persistence failed — genuinely unrecoverable.
            fatalError("Failed to create Cairn ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            WatchRootView(storeBacking: storeResult.backing)
        }
        .modelContainer(storeResult.container)
    }
}
