import Foundation
import Testing
@testable import Cairn

struct CreditScoreTests {
    @Test(arguments: [
        (CreditScoreProvider.experian, CreditScoreScale.experian999),
        (.experian, .experian1250),
        (.equifax, .equifax1000),
        (.transUnion, .transUnion710),
        (.transUnion, .transUnion999)
    ])
    func acceptsProviderScales(provider: CreditScoreProvider, scale: CreditScoreScale) throws {
        let date = Date(timeIntervalSince1970: 0)
        let score = try CreditScore(provider: provider, scale: scale, value: scale.maximum, updatedAt: date)
        let zero = try CreditScore(provider: provider, scale: scale, value: 0, updatedAt: date)
        #expect(score.value == scale.maximum)
        #expect(zero.value == 0)
        #expect(score.source == .manual)
    }

    @Test func rejectsMismatchedProviderAndScale() {
        #expect(throws: CreditScore.ValidationError.scaleProviderMismatch) {
            try CreditScore(provider: .equifax, scale: .experian1250, value: 500, updatedAt: Date())
        }
    }

    @Test func rejectsValuesOutsideSelectedScale() {
        #expect(throws: CreditScore.ValidationError.outOfRange) {
            try CreditScore(provider: .experian, scale: .experian999, value: 1000, updatedAt: Date())
        }
        #expect(throws: CreditScore.ValidationError.outOfRange) {
            try CreditScore(provider: .transUnion, scale: .transUnion710, value: -1, updatedAt: Date())
        }
    }
}
