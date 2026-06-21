import Foundation
import SwiftData

@Model
public final class Moment {
    public var id: UUID = UUID()
    public var timestamp: Date = Date()
    public var categoryRaw: String = MomentCategory.contentment.rawValue

    public var category: MomentCategory {
        get { MomentCategory(rawValue: categoryRaw) ?? .contentment }
        set { categoryRaw = newValue.rawValue }
    }

    public init(
        id: UUID = UUID(),
        timestamp: Date = Date(),
        category: MomentCategory = .contentment
    ) {
        self.id = id
        self.timestamp = timestamp
        categoryRaw = category.rawValue
    }
}
