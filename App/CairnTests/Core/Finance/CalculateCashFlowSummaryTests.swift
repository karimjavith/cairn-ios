//
//  CalculateCashFlowSummaryTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CalculateCashFlowSummaryTests {

    @Test func noTransactionsReturnsZeroInflowsOutflowsAndNet() async throws {
        let summary = try await makeCalculator()(start: date(1_000), end: date(2_000), currencyCode: "GBP")

        try expectSummary(summary, start: date(1_000), end: date(2_000), inflows: 0, outflows: 0, net: 0)
    }

    @Test func singleInflowAggregates() async throws {
        let transaction = try makeTransaction(direction: .inflow, amount: Money(amount: 25, currencyCode: "GBP"))
        let summary = try await makeCalculator(transactions: [transaction])(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 25, outflows: 0, net: 25)
    }

    @Test func multipleInflowsAggregate() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 12.30, currencyCode: "GBP")),
            makeTransaction(direction: .inflow, amount: Money(amount: 7.70, currencyCode: "GBP")),
            makeTransaction(direction: .inflow, amount: Money(amount: 10, currencyCode: "GBP"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 30, outflows: 0, net: 30)
    }

    @Test func singleOutflowAggregates() async throws {
        let transaction = try makeTransaction(direction: .outflow, amount: Money(amount: 15, currencyCode: "GBP"))
        let summary = try await makeCalculator(transactions: [transaction])(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 0, outflows: 15, net: -15)
    }

    @Test func multipleOutflowsAggregate() async throws {
        let transactions = try [
            makeTransaction(direction: .outflow, amount: Money(amount: 20, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 5.50, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 4.50, currencyCode: "GBP"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 0, outflows: 30, net: -30)
    }

    @Test func mixedInflowsAndOutflowsCalculatePositiveNet() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 100, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 40, currencyCode: "GBP")),
            makeTransaction(direction: .inflow, amount: Money(amount: 10, currencyCode: "GBP"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 110, outflows: 40, net: 70)
    }

    @Test func mixedInflowsAndOutflowsCalculateZeroNet() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 50, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 20, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 30, currencyCode: "GBP"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 50, outflows: 50, net: 0)
    }

    @Test func mixedInflowsAndOutflowsCalculateNegativeNet() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 40, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 75, currencyCode: "GBP"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 40, outflows: 75, net: -35)
    }

    @Test func queryUsesRequestedStartAndEnd() async throws {
        let repository = InMemoryCashFlowTransactionRepository()
        let calculator = CalculateCashFlowSummary(transactionRepository: repository)
        let start = date(1_234)
        let end = date(5_678)

        _ = try await calculator(start: start, end: end, currencyCode: "GBP")

        let requestedRanges = await repository.requestedRanges()
        #expect(requestedRanges == [RequestedRange(start: start, end: end)])
    }

    @Test func periodBoundariesFollowRepositoryContract() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 100, currencyCode: "GBP"), occurredAt: date(999)),
            makeTransaction(direction: .inflow, amount: Money(amount: 10, currencyCode: "GBP"), occurredAt: date(1_000)),
            makeTransaction(direction: .outflow, amount: Money(amount: 3, currencyCode: "GBP"), occurredAt: date(1_500)),
            makeTransaction(direction: .inflow, amount: Money(amount: 50, currencyCode: "GBP"), occurredAt: date(2_000)),
            makeTransaction(direction: .outflow, amount: Money(amount: 25, currencyCode: "GBP"), occurredAt: date(2_001))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, start: date(1_000), end: date(2_000), inflows: 10, outflows: 3, net: 7)
    }

    @Test func invalidEqualPeriodFailsBeforeRepositoryCall() async throws {
        let repository = InMemoryCashFlowTransactionRepository()
        let calculator = CalculateCashFlowSummary(transactionRepository: repository)
        let start = date(1_000)

        do {
            _ = try await calculator(start: start, end: start, currencyCode: "GBP")
            Issue.record("Expected invalid period to fail.")
        } catch let error as CalculateCashFlowSummary.Error {
            #expect(error == .invalidPeriod)
        }

        #expect(await repository.requestedRanges() == [])
    }

    @Test func invalidReversedPeriodFailsBeforeRepositoryCall() async throws {
        let repository = InMemoryCashFlowTransactionRepository()
        let calculator = CalculateCashFlowSummary(transactionRepository: repository)

        do {
            _ = try await calculator(start: date(2_000), end: date(1_000), currencyCode: "GBP")
            Issue.record("Expected invalid period to fail.")
        } catch let error as CalculateCashFlowSummary.Error {
            #expect(error == .invalidPeriod)
        }

        #expect(await repository.requestedRanges() == [])
    }

    @Test func infiniteStartPeriodFailsBeforeRepositoryCall() async throws {
        try await expectInvalidPeriodWithoutRepositoryCall(
            start: Date(timeIntervalSinceReferenceDate: .infinity),
            end: date(2_000)
        )
    }

    @Test func infiniteEndPeriodFailsBeforeRepositoryCall() async throws {
        try await expectInvalidPeriodWithoutRepositoryCall(
            start: date(1_000),
            end: Date(timeIntervalSinceReferenceDate: .infinity)
        )
    }

    @Test func negativeInfiniteStartPeriodFailsBeforeRepositoryCall() async throws {
        try await expectInvalidPeriodWithoutRepositoryCall(
            start: Date(timeIntervalSinceReferenceDate: -.infinity),
            end: date(2_000)
        )
    }

    @Test func negativeInfiniteEndPeriodFailsBeforeRepositoryCall() async throws {
        try await expectInvalidPeriodWithoutRepositoryCall(
            start: date(1_000),
            end: Date(timeIntervalSinceReferenceDate: -.infinity)
        )
    }

    @Test func requestedCurrencyTransactionsContributeAndOtherCurrenciesAreExcluded() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 100, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 20, currencyCode: "GBP")),
            makeTransaction(direction: .inflow, amount: Money(amount: 999, currencyCode: "EUR")),
            makeTransaction(direction: .outflow, amount: Money(amount: 888, currencyCode: "USD"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 100, outflows: 20, net: 80)
        #expect(summary.totalInflows.currencyCode == "GBP")
        #expect(summary.totalOutflows.currencyCode == "GBP")
        #expect(summary.netCashFlow.currencyCode == "GBP")
    }

    @Test func onlyOtherCurrencyTransactionsReturnZerosInRequestedCurrency() async throws {
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: 100, currencyCode: "EUR")),
            makeTransaction(direction: .outflow, amount: Money(amount: 50, currencyCode: "USD"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "gbp"
        )

        try expectSummary(summary, inflows: 0, outflows: 0, net: 0)
        #expect(summary.totalInflows.currencyCode == "GBP")
        #expect(summary.totalOutflows.currencyCode == "GBP")
        #expect(summary.netCashFlow.currencyCode == "GBP")
    }

    @Test func highPrecisionDecimalValuesRemainExact() async throws {
        let inflowAmount = try decimal("1.000000000000000006")
        let outflowAmount = try decimal("0.000000000000000004")
        let transactions = try [
            makeTransaction(direction: .inflow, amount: Money(amount: inflowAmount, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: outflowAmount, currencyCode: "GBP"))
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(
            summary,
            inflows: inflowAmount,
            outflows: outflowAmount,
            net: try decimal("1.000000000000000002")
        )
    }

    @Test func transactionOrderingDoesNotAffectTotals() async throws {
        let transactions = try [
            makeTransaction(direction: .outflow, amount: Money(amount: 12.34, currencyCode: "GBP")),
            makeTransaction(direction: .inflow, amount: Money(amount: 50, currencyCode: "GBP")),
            makeTransaction(direction: .outflow, amount: Money(amount: 7.66, currencyCode: "GBP"))
        ]
        let forward = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )
        let reversed = try await makeCalculator(transactions: Array(transactions.reversed()))(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(forward, inflows: 50, outflows: 20, net: 30)
        #expect(reversed == forward)
    }

    @Test func metadataDoesNotAffectQualification() async throws {
        let firstCategoryID = CategoryID()
        let secondCategoryID = CategoryID()
        let transactions = try [
            makeTransaction(
                accountID: AccountID(),
                direction: .inflow,
                amount: Money(amount: 10, currencyCode: "GBP"),
                categoryID: firstCategoryID,
                memo: "Salary"
            ),
            makeTransaction(
                accountID: AccountID(),
                direction: .outflow,
                amount: Money(amount: 4, currencyCode: "GBP"),
                categoryID: secondCategoryID,
                memo: "Lunch"
            ),
            makeTransaction(
                accountID: AccountID(),
                direction: .inflow,
                amount: Money(amount: 6, currencyCode: "GBP"),
                categoryID: nil,
                memo: nil
            )
        ]
        let summary = try await makeCalculator(transactions: transactions)(
            start: date(1_000),
            end: date(2_000),
            currencyCode: "GBP"
        )

        try expectSummary(summary, inflows: 16, outflows: 4, net: 12)
    }

    @Test func transactionRepositoryFailurePropagatesUnchanged() async throws {
        let calculator = makeCalculator(fetchError: CashFlowRepositoryError.fetchFailed)

        do {
            _ = try await calculator(start: date(1_000), end: date(2_000), currencyCode: "GBP")
            Issue.record("Expected repository failure to propagate.")
        } catch let error as CashFlowRepositoryError {
            #expect(error == .fetchFailed)
        }
    }

    @Test func calculateCashFlowSummaryIsSendable() {
        let calculator = CalculateCashFlowSummary(transactionRepository: InMemoryCashFlowTransactionRepository())

        requireSendable(calculator)
    }

    private func makeCalculator(
        transactions: [Transaction] = [],
        fetchError: CashFlowRepositoryError? = nil
    ) -> CalculateCashFlowSummary {
        CalculateCashFlowSummary(
            transactionRepository: InMemoryCashFlowTransactionRepository(
                transactions: transactions,
                fetchError: fetchError
            )
        )
    }

    private func expectInvalidPeriodWithoutRepositoryCall(
        start: Date,
        end: Date
    ) async throws {
        let repository = InMemoryCashFlowTransactionRepository()
        let calculator = CalculateCashFlowSummary(transactionRepository: repository)

        do {
            _ = try await calculator(start: start, end: end, currencyCode: "GBP")
            Issue.record("Expected invalid period to fail.")
        } catch let error as CalculateCashFlowSummary.Error {
            #expect(error == .invalidPeriod)
        }

        #expect(await repository.requestedRanges() == [])
    }

    private func makeTransaction(
        accountID: AccountID = AccountID(),
        direction: TransactionDirection,
        amount: Money,
        occurredAt: Date = Date(timeIntervalSince1970: 1_500),
        categoryID: CategoryID? = nil,
        memo: String? = "Memo"
    ) throws -> Transaction {
        try Transaction(
            accountID: accountID,
            direction: direction,
            amount: amount,
            occurredAt: occurredAt,
            categoryID: categoryID,
            memo: memo
        )
    }

    private func expectSummary(
        _ summary: CashFlowSummary,
        start: Date = Date(timeIntervalSince1970: 1_000),
        end: Date = Date(timeIntervalSince1970: 2_000),
        inflows: Decimal,
        outflows: Decimal,
        net: Decimal,
        sourceLocation: SourceLocation = #_sourceLocation
    ) throws {
        #expect(summary.period == (try CashFlowSummaryPeriod(start: start, end: end)), sourceLocation: sourceLocation)
        #expect(summary.totalInflows == (try Money(amount: inflows, currencyCode: "GBP")), sourceLocation: sourceLocation)
        #expect(summary.totalOutflows == (try Money(amount: outflows, currencyCode: "GBP")), sourceLocation: sourceLocation)
        #expect(summary.netCashFlow == (try Money(amount: net, currencyCode: "GBP")), sourceLocation: sourceLocation)
    }

    private func decimal(_ value: String) throws -> Decimal {
        try #require(Decimal(string: value))
    }

    private func date(_ timeIntervalSince1970: TimeInterval) -> Date {
        Date(timeIntervalSince1970: timeIntervalSince1970)
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}

private enum CashFlowRepositoryError: Error, Equatable, Sendable {
    case fetchFailed
}

private struct RequestedRange: Equatable, Sendable {
    let start: Date
    let end: Date
}

private actor InMemoryCashFlowTransactionRepository: TransactionRepository {
    private var transactions: [Transaction]
    private var ranges: [RequestedRange] = []
    private let fetchError: CashFlowRepositoryError?

    init(
        transactions: [Transaction] = [],
        fetchError: CashFlowRepositoryError? = nil
    ) {
        self.transactions = transactions
        self.fetchError = fetchError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        transactions.filter { $0.accountID == accountID }
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        transactions.filter { $0.categoryID == categoryID }
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        ranges.append(RequestedRange(start: start, end: end))

        if let fetchError {
            throw fetchError
        }

        guard start < end else {
            throw TransactionRepositoryError.invalidDateRange
        }

        return transactions.filter { start <= $0.occurredAt && $0.occurredAt < end }
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        transactions.first { $0.id == id }
    }

    func save(_ transaction: Transaction) async throws {
        transactions.append(transaction)
    }

    func deleteTransaction(id: TransactionID) async throws {
        transactions.removeAll { $0.id == id }
    }

    func requestedRanges() -> [RequestedRange] {
        ranges
    }
}
