import CairnCore
import SwiftData
import SwiftUI

@main
struct CairnApp: App {
    private let sharedModelContainer: ModelContainer = {
        let schema = Schema([Moment.self])
        let configuration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false,
            cloudKitDatabase: .private("iCloud.com.markderdzinski.Cairn")
        )
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Failed to create Cairn ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .task {
                    migrateSluggishnessToHeaviness()
                }
        }
        .modelContainer(sharedModelContainer)
    }

    @MainActor
    private func migrateSluggishnessToHeaviness() {
        let context = ModelContext(sharedModelContainer)
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
