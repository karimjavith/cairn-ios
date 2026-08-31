//
//  DashboardPresentationFormatting.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation

enum DashboardMoneyFormatter {
    static func currency(_ money: Money) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode

        return formatter.string(from: money.amount as NSDecimalNumber)
            ?? "\(money.amount) \(money.currencyCode)"
    }

    static func remainingStatusTitle(_ remaining: Money) -> String {
        remaining.amount < 0 ? "Overspent" : "Remaining"
    }

    static func remainingStatusValue(_ remaining: Money) -> String {
        let displayedMoney = remaining.amount < 0 ? -remaining : remaining

        return currency(displayedMoney)
    }
}

enum DashboardDateFormatter {
    static func date(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        return formatter.string(from: date)
    }

    static func dateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        return formatter.string(from: date)
    }

    static func period(_ period: CashFlowSummaryPeriod) -> String {
        "\(date(period.start)) - \(date(period.end))"
    }
}

nonisolated struct DashboardHeroPresentation: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case singleCurrencyNetWorth(Money)
        case currencyTotals([DashboardCurrencyTotal])
    }

    let title: String
    let subtitle: String
    let kind: Kind
    let accessibilityLabel: String

    static func make(snapshot: DashboardSnapshot) -> DashboardHeroPresentation? {
        if let netWorth = snapshot.singleCurrencyNetWorth {
            let value = CairnMoneyPresentation.currency(netWorth)
            return DashboardHeroPresentation(
                title: "Net worth",
                subtitle: accountSummary(snapshot.accountBalances.count, currencyCode: netWorth.currencyCode),
                kind: .singleCurrencyNetWorth(netWorth),
                accessibilityLabel: "Net worth, \(value), \(accountSummary(snapshot.accountBalances.count, currencyCode: netWorth.currencyCode))"
            )
        }

        guard snapshot.currencyTotals.isEmpty == false else {
            return nil
        }

        let totalsLabel = snapshot.currencyTotals
            .map { "\(CairnMoneyPresentation.currency($0.total)) \($0.currencyCode)" }
            .joined(separator: ", ")

        return DashboardHeroPresentation(
            title: "Balances",
            subtitle: "Cairn does not convert currencies.",
            kind: .currencyTotals(snapshot.currencyTotals),
            accessibilityLabel: "Balances by currency, \(totalsLabel). Cairn does not convert currencies."
        )
    }

    private static func accountSummary(_ count: Int, currencyCode: String) -> String {
        let accountText = count == 1 ? "1 account" : "\(count) accounts"
        return "\(accountText) in \(currencyCode)"
    }
}

nonisolated struct DashboardCashFlowEmptyPromptPresentation: Equatable, Sendable {
    enum Action: Equatable, Sendable {
        case addAccount
        case openTransactions
    }

    let title: String
    let message: String
    let buttonTitle: String
    let action: Action

    static func make(snapshot: DashboardSnapshot) -> DashboardCashFlowEmptyPromptPresentation? {
        if snapshot.accountBalances.isEmpty {
            return DashboardCashFlowEmptyPromptPresentation(
                title: "Add an account first",
                message: "Cash flow needs an account currency before activity can be tracked.",
                buttonTitle: "Add account",
                action: .addAccount
            )
        }

        guard snapshot.cashFlowSummaries.isEmpty || hasCashFlowActivity(snapshot) == false else {
            return nil
        }

        return DashboardCashFlowEmptyPromptPresentation(
            title: "Ready for activity",
            message: "Record income or spending to see monthly cash flow here.",
            buttonTitle: "Open transactions",
            action: .openTransactions
        )
    }

    private static func hasCashFlowActivity(_ snapshot: DashboardSnapshot) -> Bool {
        snapshot.cashFlowSummaries.contains { cashFlow in
            cashFlow.summary.totalInflows.amount != 0
                || cashFlow.summary.totalOutflows.amount != 0
                || cashFlow.summary.netCashFlow.amount != 0
        }
    }
}

nonisolated struct DashboardProgressSummaryPresentationItem<ID: Hashable & Sendable>: Equatable, Sendable {
    let id: ID
    let presentation: CairnProgressPresentation
}

enum DashboardProgressSectionPresentation {
    static func budgetItems(snapshot: DashboardSnapshot) -> [DashboardProgressSummaryPresentationItem<BudgetID>] {
        snapshot.budgetProgress.map { status in
            DashboardProgressSummaryPresentationItem(
                id: status.progress.budget.id,
                presentation: CairnProgressPresentation.budget(
                    title: status.categoryName,
                    spent: status.progress.spent,
                    limit: status.progress.budget.limit,
                    remaining: status.progress.remaining
                )
            )
        }
    }

    static func goalItems(snapshot: DashboardSnapshot) -> [DashboardProgressSummaryPresentationItem<GoalID>] {
        snapshot.goalProgress.map { status in
            DashboardProgressSummaryPresentationItem(
                id: status.progress.goal.id,
                presentation: CairnProgressPresentation.goal(
                    title: status.progress.goal.name,
                    saved: status.progress.goal.currentAmount,
                    target: status.progress.goal.targetAmount,
                    ratio: status.progress.progressRatio
                )
            )
        }
    }
}
