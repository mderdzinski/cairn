import Foundation
import SwiftData

@Model
public final class Moment {
    #Index<Moment>([\.timestamp])

    public var id: UUID = UUID()
    public var timestamp: Date = Date()
    public var categoryRaw: String = MomentCategory.contentment.rawValue
    public var reflection: String?

    public var category: MomentCategory {
        get { MomentCategory(rawValue: categoryRaw) ?? .contentment }
        set { categoryRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: MomentCategory = .contentment,
        reflection: String? = nil
    ) {
        self.id = id
        self.timestamp = timestamp
        categoryRaw = category.rawValue
        self.reflection = reflection
    }
}
