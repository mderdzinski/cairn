import CairnCore
import SwiftData
import SwiftUI

enum CairnTab: Hashable {
    case capture
    case path
    case patterns
}

struct RootTabView: View {
    @State private var selection: CairnTab = .capture

    var body: some View {
        TabView(selection: $selection) {
            CaptureView(onSeePath: { selection = .path })
                .tabItem {
                    Label("Capture", systemImage: "plus")
                }
                .tag(CairnTab.capture)

            TimelineView()
                .tabItem {
                    Label("Path", systemImage: "mountain.2")
                }
                .tag(CairnTab.path)

            PatternsView()
                .tabItem {
                    Label("Patterns", systemImage: "chart.bar")
                }
                .tag(CairnTab.patterns)
        }
        .tint(.cairnAccent)
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Moment.self, inMemory: true)
}
