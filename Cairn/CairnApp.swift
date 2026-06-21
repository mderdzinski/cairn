import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnApp: App {
    var body: some Scene {
        WindowGroup {
            CaptureView()
        }
        .modelContainer(for: Moment.self)
    }
}
