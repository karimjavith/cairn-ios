//
//  Goal.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

import Foundation

nonisolated struct GoalID: Equatable, Hashable, Codable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

nonisolated struct Goal: Equatable, Hashable, Sendable {
    let id: GoalID
    let name: String
    let targetAmount: Money
    let currentAmount: Money
    let targetDate: Date?

    init(
        id: GoalID = GoalID(),
        name: String,
        targetAmount: Money,
        currentAmount: Money,
        targetDate: Date? = nil
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyName
        }

        guard targetAmount.amount >= 0 else {
            throw ValidationError.negativeTargetAmount
        }

        guard currentAmount.amount >= 0 else {
            throw ValidationError.negativeCurrentAmount
        }

        guard currentAmount.currencyCode == targetAmount.currencyCode else {
            throw ValidationError.currencyMismatch(
                targetCurrencyCode: targetAmount.currencyCode,
                currentCurrencyCode: currentAmount.currencyCode
            )
        }

        guard currentAmount.amount <= targetAmount.amount else {
            throw ValidationError.currentAmountExceedsTargetAmount
        }

        self.id = id
        self.name = trimmedName
        self.targetAmount = targetAmount
        self.currentAmount = currentAmount
        self.targetDate = targetDate
    }
}

extension Goal {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case emptyName
        case negativeTargetAmount
        case negativeCurrentAmount
        case currencyMismatch(
            targetCurrencyCode: String,
            currentCurrencyCode: String
        )
        case currentAmountExceedsTargetAmount
    }
}

nonisolated extension Goal: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case targetAmount
        case targetCurrencyCode
        case currentAmount
        case currentCurrencyCode
        case targetDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let targetAmount = try Money(
            amount: container.decode(Decimal.self, forKey: .targetAmount),
            currencyCode: container.decode(String.self, forKey: .targetCurrencyCode)
        )
        let currentAmount = try Money(
            amount: container.decode(Decimal.self, forKey: .currentAmount),
            currencyCode: container.decode(String.self, forKey: .currentCurrencyCode)
        )

        try self.init(
            id: container.decode(GoalID.self, forKey: .id),
            name: container.decode(String.self, forKey: .name),
            targetAmount: targetAmount,
            currentAmount: currentAmount,
            targetDate: container.decodeIfPresent(Date.self, forKey: .targetDate)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(targetAmount.amount, forKey: .targetAmount)
        try container.encode(targetAmount.currencyCode, forKey: .targetCurrencyCode)
        try container.encode(currentAmount.amount, forKey: .currentAmount)
        try container.encode(currentAmount.currencyCode, forKey: .currentCurrencyCode)
        try container.encodeIfPresent(targetDate, forKey: .targetDate)
    }
}
