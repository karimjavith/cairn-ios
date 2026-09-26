import Foundation
import SwiftData

extension CairnSchemaV2 {
    @Model
    nonisolated final class CreditScoreRecord {
        @Attribute(.unique) var provider: String
        var scale: String
        var value: Int
        var updatedAt: Date
        var source: String

        init(provider: String, scale: String, value: Int, updatedAt: Date, source: String) {
            self.provider = provider
            self.scale = scale
            self.value = value
            self.updatedAt = updatedAt
            self.source = source
        }
    }
}

typealias CreditScoreRecord = CairnSchemaV2.CreditScoreRecord

extension CreditScoreRecord {
    convenience init(score: CreditScore) {
        self.init(
            provider: score.provider.rawValue,
            scale: score.scale.rawValue,
            value: score.value,
            updatedAt: score.updatedAt,
            source: score.source.rawValue
        )
    }

    func creditScore() throws -> CreditScore {
        guard let provider = CreditScoreProvider(rawValue: provider),
              let scale = CreditScoreScale(rawValue: scale),
              let source = CreditScoreSource(rawValue: source) else {
            throw CreditScoreRecordMappingError.invalidRecord
        }
        return try CreditScore(
            provider: provider,
            scale: scale,
            value: value,
            updatedAt: updatedAt,
            source: source
        )
    }

    func apply(_ score: CreditScore) {
        scale = score.scale.rawValue
        value = score.value
        updatedAt = score.updatedAt
        source = score.source.rawValue
    }
}

nonisolated enum CreditScoreRecordMappingError: Error, Equatable, Sendable {
    case invalidRecord
}
