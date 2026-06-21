import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    await migrateSluggishnessToHeaviness()
                }
        }
        .modelContainer(for: Moment.self)
    }

    @MainActor
    private func migrateSluggishnessToHeaviness() async {
        guard let container = try? ModelContainer(for: Moment.self) else { return }
        let context = ModelContext(container)
        let descriptor = FetchDescriptor<Moment>(
            predicate: #Predicate { $0.categoryRaw == "sluggishness" }
        )
        guard let stale = try? context.fetch(descriptor), !stale.isEmpty else { return }
        for moment in stale {
            moment.categoryRaw = MomentCategory.heaviness.rawValue
        }
        try? context.save()
    }
}
