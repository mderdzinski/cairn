import CairnCore
import SwiftData
import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            CaptureView()
                .tabItem {
                    Label("Capture", systemImage: "plus")
                }

            TimelineView()
                .tabItem {
                    Label("Path", systemImage: "mountain.2")
                }

            PatternsView()
                .tabItem {
                    Label("Patterns", systemImage: "chart.bar")
                }
        }
        .tint(.cairnAccent)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Moment.self, inMemory: true)
}
