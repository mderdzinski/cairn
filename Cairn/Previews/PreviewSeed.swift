import CairnCore
import SwiftData
import SwiftUI

/// Sample data for Xcode previews. Seeds a few days of moments, some already
/// reflected on, so layout work (iPhone Duo's inner display in particular) can
/// be judged against a populated Path and Patterns instead of empty states.
/// Preview-only: nothing here ships in the app's runtime paths.
enum PreviewSeed {
    @MainActor
    static func container() -> ModelContainer {
        let schema = Schema([Moment.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        guard let container = try? ModelContainer(for: schema, configurations: [config]) else {
            // Previews can't recover from a failed container, so a crash is the
            // right signal; this never runs outside the canvas.
            fatalError("PreviewSeed: could not create in-memory ModelContainer")
        }
        let context = container.mainContext
        let now = Date.now
        for sample in samples {
            context.insert(Moment(
                timestamp: now.addingTimeInterval(-sample.hoursAgo * 3600),
                category: sample.category,
                reflection: sample.reflection
            ))
        }
        return container
    }

    private struct Sample {
        let hoursAgo: Double
        let category: MomentCategory
        let reflection: String?

        init(_ hoursAgo: Double, _ category: MomentCategory, _ reflection: String? = nil) {
            self.hoursAgo = hoursAgo
            self.category = category
            self.reflection = reflection
        }
    }

    private static let samples: [Sample] = [
        Sample(1.5, .contentment),
        Sample(4, .restlessness),
        Sample(7, .desire, "Scrolling again while the kettle boiled. Not hungry for anything in particular."),
        Sample(26, .aversion),
        Sample(30, .contentment, "The walk back from the station, cold air, nothing to solve."),
        Sample(52, .heaviness),
        Sample(55, .doubt, "Second-guessed the message for ten minutes, then sent the first draft."),
        Sample(76, .contentment),
        Sample(100, .restlessness),
        Sample(124, .contentment, "Long lunch with no phone on the table."),
    ]
}
