@testable import CairnCore
import Foundation
import Testing

@Suite("MomentCategory")
struct MomentCategoryTests {
    @Test("has exactly six cases")
    func caseCount() {
        #expect(MomentCategory.allCases.count == 6)
    }

    @Test("every case has a non-empty display name")
    func displayNames() {
        for category in MomentCategory.allCases {
            #expect(!category.displayName.isEmpty)
        }
    }

    @Test("every case has a non-empty summary")
    func summaries() {
        for category in MomentCategory.allCases {
            #expect(!category.summary.isEmpty)
        }
    }

    @Test("contentment is present as the positive pole")
    func contentmentExists() {
        #expect(MomentCategory.allCases.contains(.contentment))
    }

    @Test("all five hindrances are present")
    func hindrancesExist() {
        let hindrances: Set<MomentCategory> = [.desire, .aversion, .restlessness, .sluggishness, .doubt]
        #expect(hindrances.isSubset(of: Set(MomentCategory.allCases)))
    }

    @Test("codable roundtrip preserves value", arguments: MomentCategory.allCases)
    func codableRoundtrip(category: MomentCategory) throws {
        let data = try JSONEncoder().encode(category)
        let decoded = try JSONDecoder().decode(MomentCategory.self, from: data)
        #expect(decoded == category)
    }
}
