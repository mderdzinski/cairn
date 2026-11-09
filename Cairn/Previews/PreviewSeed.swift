import CairnCore
import SwiftData
import SwiftUI

/// Sample data for Xcode previews and the `-cairn.demo.seed` screenshot launch
/// (see `DemoLaunch`). Seeds a week of moments, some already reflected on, so
/// layout work (iPhone Duo's inner display in particular) and App Store
/// captures show a populated Path and Patterns instead of empty states. Never
/// touches the user's store: only in-memory containers are ever seeded.
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
        seed(into: container.mainContext)
        return container
    }

    /// Inserts the sample moments relative to now. The caller owns the context
    /// and is expected to pass an in-memory one.
    @MainActor
    static func seed(into context: ModelContext) {
        let now = Date.now
        for sample in samples {
            context.insert(Moment(
                timestamp: now.addingTimeInterval(-sample.hoursAgo * 3600),
                category: sample.category,
                reflection: sample.reflection
            ))
        }
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
        Sample(9, .aversion),
        Sample(26, .aversion),
        Sample(28, .desire),
        Sample(30, .contentment, "The walk back from the station, cold air, nothing to solve."),
        Sample(49, .contentment, "Rain on the skylight during the call. Didn't mind the delay."),
        Sample(52, .heaviness),
        Sample(55, .doubt, "Second-guessed the message for ten minutes, then sent the first draft."),
        Sample(76, .contentment),
        Sample(78, .doubt),
        Sample(98, .contentment),
        Sample(100, .restlessness),
        Sample(124, .contentment, "Long lunch with no phone on the table."),
        Sample(128, .heaviness, "Afternoon fog after lunch. Moved the hard task to tomorrow."),
        Sample(150, .restlessness),
        Sample(152, .contentment),
    ]
}
