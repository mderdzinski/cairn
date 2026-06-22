import Foundation

public extension MomentCategory {
    var isContentment: Bool {
        self == .contentment
    }
}

public enum PatternsRange: String, CaseIterable, Sendable {
    case week
    case month

    public var displayName: String {
        switch self {
        case .week: "This week"
        case .month: "This month"
        }
    }

    public var dayCount: Int {
        switch self {
        case .week: 7
        case .month: 30
        }
    }
}
