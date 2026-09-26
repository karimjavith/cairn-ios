import Foundation
import SwiftData

@ModelActor
actor SwiftDataCreditScoreRepository: CreditScoreRepository {
    func fetchScores() async throws -> [CreditScore] {
        let descriptor = FetchDescriptor<CreditScoreRecord>()
        return try modelContext.fetch(descriptor)
            .map { try $0.creditScore() }
            .sorted { $0.provider.displayName < $1.provider.displayName }
    }

    func save(_ score: CreditScore) async throws {
        let provider = score.provider.rawValue
        var descriptor = FetchDescriptor<CreditScoreRecord>(
            predicate: #Predicate { $0.provider == provider }
        )
        descriptor.fetchLimit = 1

        if let record = try modelContext.fetch(descriptor).first {
            record.apply(score)
        } else {
            modelContext.insert(CreditScoreRecord(score: score))
        }
        try modelContext.save()
    }
}
