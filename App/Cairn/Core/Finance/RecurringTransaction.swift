//
//  RecurringTransaction.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

import Foundation

nonisolated struct RecurringTransactionID: Equatable, Hashable, Codable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

nonisolated enum RecurrenceFrequency: Equatable, Hashable, Codable, Sendable {
    case daily
    case weekly
    case monthly
    case yearly
}

nonisolated struct RecurringTransaction: Equatable, Hashable, Sendable {
    let id: RecurringTransactionID
    let accountID: AccountID
    let direction: TransactionDirection
    let amount: Money
    let frequency: RecurrenceFrequency
    let startDate: Date
    let endDate: Date?
    let memo: String?

    init(
        id: RecurringTransactionID = RecurringTransactionID(),
        accountID: AccountID,
        direction: TransactionDirection,
        amount: Money,
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date? = nil,
        memo: String? = nil
    ) throws {
        guard amount.amount >= 0 else {
            throw ValidationError.negativeAmount
        }

        if let endDate {
            guard endDate > startDate else {
                throw ValidationError.invalidDateRange
            }
        }

        self.id = id
        self.accountID = accountID
        self.direction = direction
        self.amount = amount
        self.frequency = frequency
        self.startDate = startDate
        self.endDate = endDate
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

extension RecurringTransaction {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case negativeAmount
        case invalidDateRange
    }
}

nonisolated extension RecurringTransaction: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case accountID
        case direction
        case amount
        case currencyCode
        case frequency
        case startDate
        case endDate
        case memo
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let amount = try Money(
            amount: container.decode(Decimal.self, forKey: .amount),
            currencyCode: container.decode(String.self, forKey: .currencyCode)
        )

        try self.init(
            id: container.decode(RecurringTransactionID.self, forKey: .id),
            accountID: container.decode(AccountID.self, forKey: .accountID),
            direction: container.decode(TransactionDirection.self, forKey: .direction),
            amount: amount,
            frequency: container.decode(RecurrenceFrequency.self, forKey: .frequency),
            startDate: container.decode(Date.self, forKey: .startDate),
            endDate: container.decodeIfPresent(Date.self, forKey: .endDate),
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
        try container.encode(frequency, forKey: .frequency)
        try container.encode(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(memo, forKey: .memo)
    }
}
