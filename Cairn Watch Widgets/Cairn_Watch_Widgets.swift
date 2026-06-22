import SwiftUI
import WidgetKit

struct CairnCaptureLauncher: Widget {
    let kind: String = "CairnCaptureLauncher"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StaticEntryProvider()) { _ in
            CairnCaptureLauncherView()
                .widgetURL(URL(string: "cairn://capture"))
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("Capture a moment")
        .description("Tap to mark a moment in Cairn.")
        .supportedFamilies([.accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct CairnCaptureLauncherView: View {
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .accessoryInline:
            Label("Cairn", systemImage: "mountain.2")
        case .accessoryRectangular:
            HStack(spacing: 8) {
                Image(systemName: "mountain.2")
                    .font(.system(size: 18, weight: .semibold))
                Text("Capture a moment")
                    .font(.body)
                Spacer(minLength: 0)
            }
        default:
            Image(systemName: "mountain.2")
                .font(.system(size: 24, weight: .semibold))
        }
    }
}

struct CairnLauncherEntry: TimelineEntry {
    let date: Date
}

struct StaticEntryProvider: TimelineProvider {
    func placeholder(in _: Context) -> CairnLauncherEntry {
        CairnLauncherEntry(date: .now)
    }

    func getSnapshot(in _: Context, completion: @escaping (CairnLauncherEntry) -> Void) {
        completion(CairnLauncherEntry(date: .now))
    }

    func getTimeline(in _: Context, completion: @escaping (Timeline<CairnLauncherEntry>) -> Void) {
        let entry = CairnLauncherEntry(date: .now)
        completion(Timeline(entries: [entry], policy: .never))
    }
}

#Preview(as: .accessoryRectangular) {
    CairnCaptureLauncher()
} timeline: {
    CairnLauncherEntry(date: .now)
}
