import CairnCore
import SwiftData
import SwiftUI

enum CairnTab: Hashable {
    case capture
    case path
    case patterns
}

struct RootTabView: View {
    @AppStorage(RemindersSettings.storageKey) private var settingsData: Data = RemindersSettings
        .encode(RemindersSettings())
    @State private var selection: CairnTab = .capture
    @State private var capturePath = NavigationPath()
    let remindersService: RemindersService

    var body: some View {
        TabView(selection: $selection) {
            CaptureView(
                onSeePath: { route(to: .path) },
                onRoute: route(to:),
                path: $capturePath
            )
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
            // Capture a launch-time deep link (delivered before view body ran)
            if let url = remindersService.lastDeepLinkURL {
                route(url: url)
                remindersService.lastDeepLinkURL = nil
            }
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
        guard url.scheme == "cairn", let host = url.host else { return }
        switch host {
        case "capture": route(to: .capture)
        case "path": route(to: .path)
        case "patterns": route(to: .patterns)
        default: break
        }
    }

    private func route(to tab: CairnTab) {
        selection = tab
        // External routes should land on the tab root, not deep inside it.
        capturePath = NavigationPath()
    }
}

#Preview {
    RootTabView(remindersService: RemindersService())
        .modelContainer(for: Moment.self, inMemory: true)
}
