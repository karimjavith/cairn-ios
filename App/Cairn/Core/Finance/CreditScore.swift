import Foundation

nonisolated enum CreditScoreProvider: String, CaseIterable, Codable, Hashable, Sendable {
    case experian
    case equifax
    case transUnion

    var displayName: String {
        switch self {
        case .experian: "Experian"
        case .equifax: "Equifax"
        case .transUnion: "TransUnion"
        }
    }
}

nonisolated enum CreditScoreScale: String, CaseIterable, Codable, Hashable, Sendable {
    case experian999
    case experian1250
    case equifax1000
    case transUnion710
    case transUnion999

    var provider: CreditScoreProvider {
        switch self {
        case .experian999, .experian1250: .experian
        case .equifax1000: .equifax
        case .transUnion710, .transUnion999: .transUnion
        }
    }

    var maximum: Int {
        switch self {
        case .experian999, .transUnion999: 999
        case .experian1250: 1250
        case .equifax1000: 1000
        case .transUnion710: 710
        }
    }

    static func available(for provider: CreditScoreProvider) -> [Self] {
        allCases.filter { $0.provider == provider }
    }

    static func current(for provider: CreditScoreProvider) -> Self {
        switch provider {
        case .experian: .experian1250
        case .equifax: .equifax1000
        case .transUnion: .transUnion999
        }
    }
}

nonisolated enum CreditScoreSource: String, Codable, Hashable, Sendable {
    case manual
}

nonisolated struct CreditScore: Equatable, Sendable {
    enum ValidationError: Error, Equatable, Sendable {
        case scaleProviderMismatch
        case outOfRange
    }

    let provider: CreditScoreProvider
    let scale: CreditScoreScale
    let value: Int
    let updatedAt: Date
    let source: CreditScoreSource

    init(
        provider: CreditScoreProvider,
        scale: CreditScoreScale,
        value: Int,
        updatedAt: Date,
        source: CreditScoreSource = .manual
    ) throws {
        guard scale.provider == provider else { throw ValidationError.scaleProviderMismatch }
        guard (0...scale.maximum).contains(value) else { throw ValidationError.outOfRange }

        self.provider = provider
        self.scale = scale
        self.value = value
        self.updatedAt = updatedAt
        self.source = source
    }
}
