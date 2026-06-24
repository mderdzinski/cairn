import CairnCore
import SwiftData
import SwiftUI

enum CairnTab: Hashable {
    case capture
    case path
    case patterns
}

struct RootTabView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())
    @State private var selection: CairnTab = .capture
    @State private var remindersService = RemindersService()

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
        .environment(remindersService)
        .task {
            remindersService.attach(modelContainer: modelContext.container)
            let settings = RemindersSettings.decode(settingsData)
            if settings.anyEnabled {
                await remindersService.reschedule(settings: settings)
            }
        }
        .onChange(of: remindersService.lastDeepLinkURL) { _, url in
            guard let url else { return }
            route(url: url)
            remindersService.lastDeepLinkURL = nil
        }
        .onOpenURL(perform: route(url:))
    }

    private func route(url: URL) {
        guard url.scheme == "cairn" else { return }
        switch url.host {
        case "capture": selection = .capture
        case "path": selection = .path
        case "patterns": selection = .patterns
        default: break
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: Moment.self, inMemory: true)
}
