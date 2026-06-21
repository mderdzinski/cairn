import Foundation

public enum MomentCategory: String, Codable, CaseIterable, Sendable {
    case contentment
    case desire
    case aversion
    case restlessness
    case sluggishness
    case doubt

    public var displayName: String {
        switch self {
        case .contentment: "Contentment"
        case .desire: "Desire"
        case .aversion: "Aversion"
        case .restlessness: "Restlessness"
        case .sluggishness: "Sluggishness"
        case .doubt: "Doubt"
        }
    }

    public var summary: String {
        switch self {
        case .contentment: "A settled, positive presence."
        case .desire: "Craving — a pull toward something."
        case .aversion: "Resistance or irritation."
        case .restlessness: "Agitation; can't quite settle."
        case .sluggishness: "Dullness or mental fog."
        case .doubt: "Uncertainty or paralysis."
        }
    }
}
