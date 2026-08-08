//
//  BudgetRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class BudgetRecord {
    @Attribute(.unique) var id: UUID
    var categoryID: UUID
    var limitAmount: String
    var currencyCode: String
    var startDate: Date
    var endDate: Date

    init(
        id: UUID,
        categoryID: UUID,
        limitAmount: String,
        currencyCode: String,
        startDate: Date,
        endDate: Date
    ) {
        self.id = id
        self.categoryID = categoryID
        self.limitAmount = limitAmount
        self.currencyCode = currencyCode
        self.startDate = startDate
        self.endDate = endDate
    }
}

extension BudgetRecord {
    convenience init(budget: Budget) {
        self.init(
            id: budget.id.rawValue,
            categoryID: budget.categoryID.rawValue,
            limitAmount: budget.limit.amount.persistenceValue,
            currencyCode: budget.limit.currencyCode,
            startDate: budget.period.startDate,
            endDate: budget.period.endDate
        )
    }

    func budget() throws -> Budget {
        let limitAmount = try Decimal(budgetPersistenceValue: limitAmount)
        let limit = try Money(
            amount: limitAmount,
            currencyCode: currencyCode
        )
        let period = try BudgetPeriod(
            startDate: startDate,
            endDate: endDate
        )

        return try Budget(
            id: BudgetID(rawValue: id),
            categoryID: CategoryID(rawValue: categoryID),
            limit: limit,
            period: period
        )
    }
}

nonisolated enum BudgetRecordMappingError: Error, Equatable, Sendable {
    case invalidLimitAmount(String)
}

private extension Decimal {
    private nonisolated static var budgetPersistencePattern: String {
        #"\A[+-]?(?:(?:[0-9]+(?:\.[0-9]*)?)|(?:\.[0-9]+))(?:[eE][+-]?[0-9]+)?\z"#
    }

    nonisolated var persistenceValue: String {
        NSDecimalNumber(decimal: self).stringValue
    }

    nonisolated init(budgetPersistenceValue: String) throws(BudgetRecordMappingError) {
        guard budgetPersistenceValue.range(
            of: Self.budgetPersistencePattern,
            options: .regularExpression
        ) != nil,
            let amount = Decimal(string: budgetPersistenceValue) else {
            throw .invalidLimitAmount(budgetPersistenceValue)
        }

        self = amount
    }
}
