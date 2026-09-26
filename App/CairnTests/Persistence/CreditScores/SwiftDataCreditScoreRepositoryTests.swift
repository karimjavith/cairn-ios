import Foundation
import SwiftData
import Testing
@testable import Cairn

@MainActor
struct SwiftDataCreditScoreRepositoryTests {
    @Test func savesAndUpdatesOneScorePerProviderWithoutLosingScale() async throws {
        let schema = Schema(versionedSchema: CairnSchemaV2.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: schema,
            migrationPlan: CairnSchemaMigrationPlan.self,
            configurations: [configuration]
        )
        let repository = SwiftDataCreditScoreRepository(modelContainer: container)
        let date = Date(timeIntervalSince1970: 1_800_000_000)

        try await repository.save(CreditScore(provider: .experian, scale: .experian999, value: 901, updatedAt: date))
        try await repository.save(CreditScore(provider: .equifax, scale: .equifax1000, value: 850, updatedAt: date))
        try await repository.save(CreditScore(provider: .experian, scale: .experian1250, value: 1101, updatedAt: date))

        let scores = try await repository.fetchScores()
        #expect(scores.count == 2)
        #expect(scores.first(where: { $0.provider == .experian })?.value == 1101)
        #expect(scores.first(where: { $0.provider == .experian })?.scale == .experian1250)
        #expect(scores.first(where: { $0.provider == .equifax })?.value == 850)
    }
}
