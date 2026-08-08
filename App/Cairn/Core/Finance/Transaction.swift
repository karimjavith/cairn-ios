//
//  Transaction.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation

nonisolated struct TransactionID: Equatable, Hashable, Codable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

nonisolated enum TransactionDirection: Equatable, Hashable, Codable, Sendable {
    case inflow
    case outflow
}

nonisolated struct Transaction: Equatable, Hashable, Sendable {
    let id: TransactionID
    let accountID: AccountID
    let direction: TransactionDirection
    let amount: Money
    let occurredAt: Date
    let categoryID: CategoryID?
    let memo: String?

    init(
        id: TransactionID = TransactionID(),
        accountID: AccountID,
        direction: TransactionDirection,
        amount: Money,
        occurredAt: Date,
        categoryID: CategoryID? = nil,
        memo: String? = nil
    ) throws {
        guard amount.amount >= 0 else {
            throw ValidationError.negativeAmount
        }

        self.id = id
        self.accountID = accountID
        self.direction = direction
        self.amount = amount
        self.occurredAt = occurredAt
        self.categoryID = categoryID
        self.memo = Self.normalizedMemo(memo)
    }

    private static func normalizedMemo(_ memo: String?) -> String? {
        let trimmedMemo = memo?.trimmingCharacters(in: .whitespacesAndNewlines)

        guard let trimmedMemo, !trimmedMemo.isEmpty else {
            return nil
        }

        return trimmedMemo
    }
}

extension Transaction {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case negativeAmount
    }
}

nonisolated extension Transaction: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case accountID
        case direction
        case amount
        case currencyCode
        case occurredAt
        case categoryID
        case memo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let amount = try Money(
            amount: container.decode(Decimal.self, forKey: .amount),
            currencyCode: container.decode(String.self, forKey: .currencyCode)
        )

        try self.init(
            id: container.decode(TransactionID.self, forKey: .id),
            accountID: container.decode(AccountID.self, forKey: .accountID),
            direction: container.decode(TransactionDirection.self, forKey: .direction),
            amount: amount,
            occurredAt: container.decode(Date.self, forKey: .occurredAt),
            categoryID: container.decodeIfPresent(CategoryID.self, forKey: .categoryID),
            memo: container.decodeIfPresent(String.self, forKey: .memo)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(accountID, forKey: .accountID)
        try container.encode(direction, forKey: .direction)
        try container.encode(amount.amount, forKey: .amount)
        try container.encode(amount.currencyCode, forKey: .currencyCode)
        try container.encode(occurredAt, forKey: .occurredAt)
        try container.encodeIfPresent(categoryID, forKey: .categoryID)
        try container.encodeIfPresent(memo, forKey: .memo)
    }
}
