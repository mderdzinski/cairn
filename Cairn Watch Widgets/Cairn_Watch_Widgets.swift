import SwiftUI
import WidgetKit

struct CairnCaptureLauncher: Widget {
    let kind: String = "CairnCaptureLauncher"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: StaticEntryProvider()) { _ in
            CairnCaptureLauncherView()
                .widgetURL(URL(string: "cairn://capture"))
                .containerBackground(for: .widget) {
                    AccessoryWidgetBackground()
                }
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
                mark
                    .frame(width: 22, height: 22)
                Text("Capture a moment")
                    .font(.body)
                Spacer(minLength: 0)
            }
        default:
            mark
                .padding(4)
        }
    }

    // The cairn mark, drawn so it survives the always-on / tinted-face pass.
    // watchOS re-renders dimmed complications in an accented/vibrant mode that
    // flattens content by luminance; anchoring to `.primary` (rather than an
    // inherited faint style) keeps the glyph fully opaque when the display dims,
    // while `widgetAccentable()` still lets tinted faces recolor it.
    private var mark: some View {
        Image("CairnComplication")
            .renderingMode(.template)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .foregroundStyle(.primary)
            .widgetAccentable()
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
