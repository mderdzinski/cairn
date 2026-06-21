@testable import CairnCore
import Foundation
import Testing

@Suite("Moment")
struct MomentTests {
    @Test("default init yields fresh UUID, recent timestamp, and contentment category")
    func defaults() {
        let before = Date()
        let moment = Moment()
        let after = Date()

        #expect(moment.category == .contentment)
        #expect(moment.timestamp >= before)
        #expect(moment.timestamp <= after)
        #expect(moment.id.uuidString.count == 36)
    }

    @Test("two default moments have distinct ids")
    func uniqueIds() {
        let first = Moment()
        let second = Moment()
        #expect(first.id != second.id)
    }

    @Test("category is preserved through the computed accessor")
    func categoryRoundtrip() {
        let moment = Moment(category: .doubt)
        #expect(moment.category == .doubt)
        #expect(moment.categoryRaw == "doubt")
    }

    @Test("category setter updates the underlying raw value")
    func categorySetter() {
        let moment = Moment()
        moment.category = .restlessness
        #expect(moment.categoryRaw == "restlessness")
    }

    @Test("reflection defaults to nil")
    func reflectionDefaultsToNil() {
        let moment = Moment()
        #expect(moment.reflection == nil)
    }

    @Test("reflection can be set at init")
    func reflectionAtInit() {
        let moment = Moment(category: .desire, reflection: "first draft")
        #expect(moment.reflection == "first draft")
    }

    @Test("reflection is mutable after init")
    func reflectionMutable() {
        let moment = Moment()
        moment.reflection = "added later"
        #expect(moment.reflection == "added later")
    }
}
