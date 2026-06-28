import Foundation
import SwiftData

/// How the ``ModelContainer`` returned by ``MomentStore.makeContainer(_:)`` was actually backed.
public enum MomentStoreBacking: Sendable, Equatable {
    /// Persistent on-disk store with CloudKit private-database sync. The happy path.
    case cloud
    /// Persistent on-disk store, no CloudKit. Used when CloudKit init throws — e.g. user is
    /// signed out of iCloud, the entitlement isn't available, or the container is misconfigured.
    case local
    /// Ephemeral in-memory store. Used for tests and previews.
    case inMemory
}

/// The result of attempting to build the app's shared ``ModelContainer`` — both the container
/// itself and a tag describing which storage path actually succeeded, so callers can surface
/// a banner when CloudKit sync isn't available.
public struct MomentStoreResult: Sendable {
    public let container: ModelContainer
    public let backing: MomentStoreBacking

    public init(container: ModelContainer, backing: MomentStoreBacking) {
        self.container = container
        self.backing = backing
    }
}

public enum MomentStore {
    /// Build the shared moments container.
    ///
    /// Tries CloudKit-backed persistence first when `cloudKitContainerID` is provided.
    /// If that throws (no iCloud, missing entitlement, etc.), falls back to a local-only
    /// store so the app still launches — sync just won't happen until iCloud is reachable.
    /// Only if both paths fail does this rethrow; that genuinely is unrecoverable and the
    /// caller should treat it as fatal.
    ///
    /// - Parameters:
    ///   - cloudKitContainerID: CloudKit container ID, or `nil` to skip CloudKit entirely.
    ///   - inMemory: when `true`, returns an ephemeral in-memory store (for tests/previews).
    /// - Returns: the container plus the backing that was actually used.
    public static func makeContainer(
        cloudKitContainerID: String?,
        inMemory: Bool = false
    ) throws -> MomentStoreResult {
        let schema = Schema([Moment.self])

        if inMemory {
            let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: schema, configurations: [configuration])
            return MomentStoreResult(container: container, backing: .inMemory)
        }

        if let cloudKitContainerID {
            let cloud = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false,
                cloudKitDatabase: .private(cloudKitContainerID)
            )
            if let container = try? ModelContainer(for: schema, configurations: [cloud]) {
                return MomentStoreResult(container: container, backing: .cloud)
            }
        }

        let local = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        let container = try ModelContainer(for: schema, configurations: [local])
        return MomentStoreResult(container: container, backing: .local)
    }
}
