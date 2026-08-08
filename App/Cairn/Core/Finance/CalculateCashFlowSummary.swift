//
//  CalculateCashFlowSummary.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation

nonisolated struct CashFlowSummaryPeriod: Equatable, Hashable, Sendable {
    let start: Date
    let end: Date

    init(start: Date, end: Date) throws {
        guard start.timeIntervalSinceReferenceDate.isFinite,
              end.timeIntervalSinceReferenceDate.isFinite,
              start < end else {
            throw CalculateCashFlowSummary.Error.invalidPeriod
        }

        self.start = start
        self.end = end
    }
}

nonisolated struct CashFlowSummary: Equatable, Sendable {
    let period: CashFlowSummaryPeriod
    let totalInflows: Money
    let totalOutflows: Money
    let netCashFlow: Money
}

nonisolated struct CalculateCashFlowSummary: Sendable {
    let transactionRepository: any TransactionRepository

    init(transactionRepository: any TransactionRepository) {
        self.transactionRepository = transactionRepository
    }

    func callAsFunction(
        start: Date,
        end: Date,
        currencyCode: String
    ) async throws -> CashFlowSummary {
        let period = try CashFlowSummaryPeriod(start: start, end: end)
        let zero = try Money(amount: 0, currencyCode: currencyCode)
        let transactions = try await transactionRepository.fetchTransactions(
            occurredFrom: period.start,
            occurredBefore: period.end
        )
        var totalInflows = zero
        var totalOutflows = zero

        for transaction in transactions where transaction.amount.currencyCode == zero.currencyCode {
            switch transaction.direction {
            case .inflow:
                totalInflows = try totalInflows.adding(transaction.amount)
            case .outflow:
                totalOutflows = try totalOutflows.adding(transaction.amount)
            }
        }

        return try CashFlowSummary(
            period: period,
            totalInflows: totalInflows,
            totalOutflows: totalOutflows,
            netCashFlow: totalInflows.subtracting(totalOutflows)
        )
    }
}

nonisolated extension CalculateCashFlowSummary {
    enum Error: Swift.Error, Equatable, Sendable {
        case invalidPeriod
    }
}
