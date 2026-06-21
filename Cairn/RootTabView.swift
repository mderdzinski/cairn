import CairnCore
import SwiftData
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "square.grid.2x2")
                }

            TimelineView()
                .tabItem {
                    Label("Timeline", systemImage: "clock")
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Moment.self, inMemory: true)
}
