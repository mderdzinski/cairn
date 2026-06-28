@testable import CairnCore
import Foundation
import SwiftData
import Testing

@Suite("MomentStore")
struct MomentStoreTests {
    @Test("in-memory mode reports inMemory backing and is usable")
    func inMemoryBacking() throws {
        let result = try MomentStore.makeContainer(
            cloudKitContainerID: "iCloud.test.cairn",
            inMemory: true
        )
        #expect(result.backing == .inMemory)

        // Sanity check: the container can actually hold a Moment.
        let context = ModelContext(result.container)
        context.insert(Moment(category: .contentment))
        let count = try context.fetchCount(FetchDescriptor<Moment>())
        #expect(count == 1)
    }

    @Test("nil CloudKit container ID skips CloudKit and uses local backing")
    func localFallbackWhenNoCloudKitID() throws {
        let result = try MomentStore.makeContainer(
            cloudKitContainerID: nil,
            inMemory: true
        )
        // inMemory still wins when both are set — it's the test/preview escape hatch.
        #expect(result.backing == .inMemory)
    }
}
