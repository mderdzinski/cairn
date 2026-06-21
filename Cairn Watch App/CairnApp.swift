import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnWatchApp: App {
    var body: some Scene {
        WindowGroup {
            WatchRootView()
        }
        .modelContainer(for: Moment.self)
    }
}
