//
//  GoalRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

extension CairnSchemaV1 {
    @Model
    nonisolated final class GoalRecord {
        @Attribute(.unique) var id: UUID
        var name: String
        var targetAmount: String
        var targetCurrencyCode: String
        var currentAmount: String
        var currentCurrencyCode: String
        var targetDate: Date?

        init(
            id: UUID,
            name: String,
            targetAmount: String,
            targetCurrencyCode: String,
            currentAmount: String,
            currentCurrencyCode: String,
            targetDate: Date?
        ) {
            self.id = id
            self.name = name
            self.targetAmount = targetAmount
            self.targetCurrencyCode = targetCurrencyCode
            self.currentAmount = currentAmount
            self.currentCurrencyCode = currentCurrencyCode
            self.targetDate = targetDate
        }
    }
}

typealias GoalRecord = CairnSchemaV1.GoalRecord

extension GoalRecord {
    convenience init(goal: Goal) {
        self.init(
            id: goal.id.rawValue,
            name: goal.name,
            targetAmount: goal.targetAmount.amount.persistenceValue,
            targetCurrencyCode: goal.targetAmount.currencyCode,
            currentAmount: goal.currentAmount.amount.persistenceValue,
            currentCurrencyCode: goal.currentAmount.currencyCode,
            targetDate: goal.targetDate
        )
    }

    func goal() throws -> Goal {
        let targetAmount = try Decimal(goalTargetPersistenceValue: targetAmount)
        let currentAmount = try Decimal(goalCurrentPersistenceValue: currentAmount)
        let targetMoney = try Money(
            amount: targetAmount,
            currencyCode: targetCurrencyCode
        )
        let currentMoney = try Money(
            amount: currentAmount,
            currencyCode: currentCurrencyCode
        )

        return try Goal(
            id: GoalID(rawValue: id),
            name: name,
            targetAmount: targetMoney,
            currentAmount: currentMoney,
            targetDate: targetDate
        )
    }
}

nonisolated enum GoalRecordMappingError: Error, Equatable, Sendable {
    case invalidTargetAmount(String)
    case invalidCurrentAmount(String)
}

private extension Decimal {
    private nonisolated static var goalPersistenceLocale: Locale {
        Locale(identifier: "en_US_POSIX")
    }

    private nonisolated static var goalPersistencePattern: String {
        #"\A[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?)|(?:\.[0-9]+))(?:[eE][+-]?[0-9]+)?\z"#
    }

    nonisolated var persistenceValue: String {
        NSDecimalNumber(decimal: self).stringValue
    }

    nonisolated init(goalTargetPersistenceValue: String) throws(GoalRecordMappingError) {
        guard goalTargetPersistenceValue.range(
            of: Self.goalPersistencePattern,
            options: .regularExpression
        ) != nil,
            let amount = Decimal(
                string: goalTargetPersistenceValue,
                locale: Self.goalPersistenceLocale
            ) else {
            throw .invalidTargetAmount(goalTargetPersistenceValue)
        }

        self = amount
    }

    nonisolated init(goalCurrentPersistenceValue: String) throws(GoalRecordMappingError) {
        guard goalCurrentPersistenceValue.range(
            of: Self.goalPersistencePattern,
            options: .regularExpression
        ) != nil,
            let amount = Decimal(
                string: goalCurrentPersistenceValue,
                locale: Self.goalPersistenceLocale
            ) else {
            throw .invalidCurrentAmount(goalCurrentPersistenceValue)
        }

        self = amount
    }
}
