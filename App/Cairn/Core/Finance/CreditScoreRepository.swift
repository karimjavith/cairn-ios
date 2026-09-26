protocol CreditScoreRepository: Sendable {
    func fetchScores() async throws -> [CreditScore]
    func save(_ score: CreditScore) async throws
}
