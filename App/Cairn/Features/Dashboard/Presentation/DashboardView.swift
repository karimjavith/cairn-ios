//
//  DashboardView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import SwiftUI

struct DashboardView: View {
    @State private var store: DashboardStore
    @ScaledMetric(relativeTo: .largeTitle) private var emptyHeroSize: CGFloat = 40
    @ScaledMetric(relativeTo: .largeTitle) private var financialHeroSize: CGFloat = 42
    private let selectTab: (AppTab) -> Void
    private let startAccountCreation: () -> Void
    private static let pageMargin: CGFloat = 24
    private static let bottomScrollClearance: CGFloat = 72

    init(
        accountRepository: any AccountRepository,
        budgetRepository: any BudgetRepository,
        goalRepository: any GoalRepository,
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        calculateAccountBalance: CalculateAccountBalance,
        calculateBudgetProgress: CalculateBudgetProgress,
        calculateGoalProgress: CalculateGoalProgress,
        calculateCashFlowSummary: CalculateCashFlowSummary,
        calendar: Calendar,
        selectTab: @escaping (AppTab) -> Void = { _ in },
        startAccountCreation: @escaping () -> Void = {}
    ) {
        self.selectTab = selectTab
        self.startAccountCreation = startAccountCreation
        _store = State(wrappedValue: DashboardStore(
            accountRepository: accountRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            calculateAccountBalance: { accountID in
                try await calculateAccountBalance(accountID: accountID)
            },
            calculateBudgetProgress: { budgetID in
                try await calculateBudgetProgress(budgetID: budgetID)
            },
            calculateGoalProgress: { goal in
                try calculateGoalProgress(goal: goal)
            },
            calculateCashFlowSummary: { start, end, currencyCode in
                try await calculateCashFlowSummary(
                    start: start,
                    end: end,
                    currencyCode: currencyCode
                )
            },
            calendar: calendar
        ))
    }

    var body: some View {
        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            Group {
                if store.isLoading {
                    loadingView
                } else if let errorMessage = store.errorMessage {
                    dashboardError(message: errorMessage)
                } else if let snapshot = store.snapshot {
                    dashboardContent(snapshot)
                } else {
                    loadingView
                }
            }
        }
        .navigationTitle("Dashboard")
        .toolbar(.hidden, for: .navigationBar)
        .task {
            await store.loadDashboard()
        }
    }

    private var loadingView: some View {
        ProgressView("Loading dashboard")
            .tint(CairnColor.plum)
            .foregroundStyle(CairnColor.textSecondary)
    }

    private func dashboardError(message: String) -> some View {
        VStack(spacing: CairnSpacing.large) {
            LoadFailureView(
                title: "Dashboard Unavailable",
                message: message,
                retry: {
                    Task {
                        await store.loadDashboard()
                    }
                }
            )
        }
        .padding(CairnSpacing.large)
    }

    private func dashboardContent(_ snapshot: DashboardSnapshot) -> some View {
        GeometryReader { proxy in
            ScrollView {
                if store.hasLoadedEmptyDashboard {
                    emptyDashboard
                        .frame(minHeight: proxy.size.height, alignment: .top)
                } else {
                    loadedDashboard(snapshot)
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: Self.bottomScrollClearance)
            }
            .scrollContentBackground(.hidden)
        }
    }

    private var emptyDashboard: some View {
        VStack(alignment: .leading, spacing: 0) {
            CairnLogoMark(scale: .compact)
                .padding(.top, CairnSpacing.medium)

            VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                Text("Your money,\nin one place.")
                    .font(.system(size: emptyHeroSize, weight: .semibold, design: .serif))
                    .lineSpacing(-1)
                    .foregroundStyle(CairnColor.textPrimary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.84)
                    .accessibilityAddTraits(.isHeader)

                Capsule()
                    .fill(CairnColor.plum)
                    .frame(width: 44, height: 3)
                    .accessibilityHidden(true)

                Text("Add your first account to see your balances, track spending, and reach your goals.")
                    .font(.body)
                    .lineSpacing(2)
                    .foregroundStyle(CairnColor.textSecondary)
                    .frame(maxWidth: 320, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 34)

            Spacer(minLength: CairnSpacing.large)

            DashboardFirstRunArtwork()
                .accessibilityHidden(true)
                .frame(maxWidth: .infinity)

            Spacer(minLength: CairnSpacing.large)

            VStack(alignment: .center, spacing: CairnSpacing.medium) {
                Button {
                    startAccountCreation()
                } label: {
                    HStack(spacing: CairnSpacing.small) {
                        Text("Add account")
                        Image(systemName: "arrow.right")
                            .font(.body.weight(.semibold))
                            .accessibilityHidden(true)
                    }
                }
                .buttonStyle(CairnPrimaryButtonStyle())

                HStack(spacing: CairnSpacing.extraSmall) {
                    Image(systemName: "lock")
                        .font(.footnote.weight(.medium))
                    Text("Your data stays on this device.")
                        .font(.footnote)
                }
                .foregroundStyle(CairnColor.textSecondary)
                .frame(maxWidth: .infinity)
                .accessibilityElement(children: .combine)
            }
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .padding(.horizontal, Self.pageMargin)
        .padding(.bottom, CairnSpacing.large)
    }

    private func loadedDashboard(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            CairnLogoMark(scale: .compact)
                .padding(.top, CairnSpacing.large)

            loadedHero(snapshot)
            cashFlowSection(snapshot)

            if snapshot.budgetProgress.isEmpty == false {
                budgetsSection(snapshot)
            }

            if snapshot.recentTransactions.isEmpty == false || hasCashFlowActivity(snapshot) {
                recentTransactionsSection(snapshot)
            }

            if snapshot.goalProgress.isEmpty == false {
                goalsSection(snapshot)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Self.pageMargin)
        .padding(.bottom, CairnSpacing.section)
    }

    @ViewBuilder
    private func loadedHero(_ snapshot: DashboardSnapshot) -> some View {
        if let hero = DashboardHeroPresentation.make(snapshot: snapshot) {
            VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                Text(hero.title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(CairnColor.plum)

                switch hero.kind {
                case let .singleCurrencyNetWorth(netWorth):
                    Text(CairnMoneyPresentation.currency(netWorth))
                        .font(.system(size: financialHeroSize, weight: .semibold))
                        .monospacedDigit()
                        .lineLimit(1)
                        .minimumScaleFactor(0.72)
                        .foregroundStyle(CairnColor.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                case let .currencyTotals(totals):
                    VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                        ForEach(totals, id: \.currencyCode) { total in
                            HStack(alignment: .firstTextBaseline) {
                                Text(total.currencyCode)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CairnColor.textSecondary)

                                Spacer(minLength: CairnSpacing.large)

                                Text(CairnMoneyPresentation.currency(total.total))
                                    .cairnRowAmount()
                                    .foregroundStyle(CairnColor.textPrimary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                }

                Text(hero.subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.top, CairnSpacing.medium)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(hero.accessibilityLabel)
        }
    }

    private func cashFlowSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            DashboardSectionTitle(
                title: "This month",
                subtitle: DashboardDateFormatter.period(snapshot.cashFlowPeriod)
            )

            if let prompt = DashboardCashFlowEmptyPromptPresentation.make(snapshot: snapshot) {
                cashFlowEmptyPrompt(prompt)
            } else if snapshot.cashFlowSummaries.count == 1, let cashFlow = snapshot.cashFlowSummaries.first {
                singleCurrencyCashFlowSummary(cashFlow.summary)
            } else {
                VStack(alignment: .leading, spacing: CairnSpacing.large) {
                    ForEach(snapshot.cashFlowSummaries, id: \.summary.totalInflows.currencyCode) { cashFlow in
                        multiCurrencyCashFlowSummary(cashFlow.summary)
                    }
                }
            }
        }
    }

    private func cashFlowEmptyPrompt(_ prompt: DashboardCashFlowEmptyPromptPresentation) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            Text(prompt.title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CairnColor.textPrimary)

            Text(prompt.message)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button(prompt.buttonTitle) {
                switch prompt.action {
                case .addAccount:
                    startAccountCreation()
                case .openTransactions:
                    selectTab(.transactions)
                }
            }
            .buttonStyle(CairnSecondaryButtonStyle())
        }
        .padding(CairnSpacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(CairnColor.lavenderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func singleCurrencyCashFlowSummary(_ summary: CashFlowSummary) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            HStack(alignment: .top, spacing: CairnSpacing.large) {
                cashFlowMetric(
                    title: "Income",
                    value: summary.totalInflows,
                    accessibilityStatus: "Money in",
                    color: CairnColor.positive
                )

                cashFlowMetric(
                    title: "Spending",
                    value: summary.totalOutflows,
                    accessibilityStatus: "Money out",
                    color: CairnColor.negative
                )

                cashFlowMetric(
                    title: "Net",
                    value: summary.netCashFlow,
                    accessibilityStatus: cashFlowNetStatus(summary.netCashFlow),
                    color: semanticColor(for: summary.netCashFlow)
                )
            }
        }
    }

    private func multiCurrencyCashFlowSummary(_ summary: CashFlowSummary) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.small) {
            Text(summary.totalInflows.currencyCode)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CairnColor.textPrimary)

            VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
                cashFlowRow(
                    title: "Income",
                    value: summary.totalInflows,
                    accessibilityStatus: "Money in",
                    color: CairnColor.positive
                )

                cashFlowRow(
                    title: "Spending",
                    value: summary.totalOutflows,
                    accessibilityStatus: "Money out",
                    color: CairnColor.negative
                )

                cashFlowRow(
                    title: "Net",
                    value: summary.netCashFlow,
                    accessibilityStatus: cashFlowNetStatus(summary.netCashFlow),
                    color: semanticColor(for: summary.netCashFlow)
                )
            }
        }
        .padding(.vertical, CairnSpacing.extraSmall)
    }

    private func cashFlowMetric(
        title: String,
        value: Money,
        accessibilityStatus: String,
        color: Color
    ) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(CairnColor.textSecondary)

            Text(CairnMoneyPresentation.currency(value))
                .font(.headline.weight(.semibold))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.82)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(CairnMoneyPresentation.currency(value)), \(accessibilityStatus)")
    }

    private func cashFlowRow(
        title: String,
        value: Money,
        accessibilityStatus: String,
        color: Color
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)

            Spacer(minLength: CairnSpacing.large)

            Text(CairnMoneyPresentation.currency(value))
                .cairnRowAmount()
                .foregroundStyle(color)
                .frame(maxWidth: 150, alignment: .trailing)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(CairnMoneyPresentation.currency(value)), \(accessibilityStatus)")
    }

    private func cashFlowNetStatus(_ money: Money) -> String {
        if money.amount > 0 {
            return "Net positive"
        }

        if money.amount < 0 {
            return "Net negative"
        }

        return "No net change"
    }

    private func semanticColor(for money: Money) -> Color {
        if money.amount > 0 {
            return CairnColor.positive
        }

        if money.amount < 0 {
            return CairnColor.negative
        }

        return CairnColor.neutral
    }

    private func hasCashFlowActivity(_ snapshot: DashboardSnapshot) -> Bool {
        snapshot.cashFlowSummaries.contains { cashFlow in
            cashFlow.summary.totalInflows.amount != 0
                || cashFlow.summary.totalOutflows.amount != 0
                || cashFlow.summary.netCashFlow.amount != 0
        }
    }

    private func budgetsSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            DashboardSectionTitle(
                title: "Budget status",
                subtitle: sectionCount(snapshot.budgetProgress.count, singular: "budget")
            )

            VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                ForEach(DashboardProgressSectionPresentation.budgetItems(snapshot: snapshot), id: \.id) { item in
                    CairnProgressSummaryView(presentation: item.presentation)
                }
            }
            .padding(.vertical, CairnSpacing.extraSmall)
        }
    }

    private func goalsSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            DashboardSectionTitle(
                title: "Goal progress",
                subtitle: sectionCount(snapshot.goalProgress.count, singular: "goal")
            )

            VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                ForEach(DashboardProgressSectionPresentation.goalItems(snapshot: snapshot), id: \.id) { item in
                    CairnProgressSummaryView(presentation: item.presentation)
                }
            }
            .padding(.vertical, CairnSpacing.extraSmall)
        }
    }

    private func recentTransactionsSection(_ snapshot: DashboardSnapshot) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            DashboardSectionTitle(title: "Recent activity", subtitle: "Current month")

            if snapshot.recentTransactions.isEmpty {
                Text("Activity will appear here once transactions are recorded this month.")
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(snapshot.recentTransactions, id: \.transaction.id) { recentTransaction in
                        transactionRow(recentTransaction)

                        if recentTransaction.transaction.id != snapshot.recentTransactions.last?.transaction.id {
                            Divider()
                                .overlay(CairnColor.separator)
                        }
                    }
                }
            }
        }
    }

    private func transactionRow(_ recentTransaction: DashboardRecentTransaction) -> some View {
        let transaction = recentTransaction.transaction
        let direction = transaction.direction.displayName
        let metadata = transactionMetadata(recentTransaction)
        let amount = CairnMoneyPresentation.currency(transaction.amount)
        let date = DashboardDateFormatter.date(transaction.occurredAt)

        return CairnFinancialRow(
            title: direction,
            metadata: metadata,
            trailing: amount,
            status: date,
            accessibilityLabel: "\(direction), \(amount), \(metadata), \(date)"
        ) {
            Image(systemName: transaction.direction == .inflow ? "arrow.down.left" : "arrow.up.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.direction == .inflow ? CairnColor.positive : CairnColor.negative)
        }
    }

    private func transactionMetadata(_ recentTransaction: DashboardRecentTransaction) -> String {
        if let memo = recentTransaction.transaction.memo, memo.isEmpty == false {
            return "\(recentTransaction.accountName) - \(memo)"
        }

        return recentTransaction.accountName
    }

    private func sectionCount(_ count: Int, singular: String) -> String {
        switch count {
        case 0:
            "None yet"
        case 1:
            "1 \(singular)"
        default:
            "\(count) \(singular)s"
        }
    }
}

private struct DashboardFirstRunArtwork: View {
    var body: some View {
        ZStack(alignment: .bottom) {
            GroundShape()
                .fill(CairnColor.lavenderSurface)
                .frame(height: 72)
                .offset(y: 12)

            GroundLineShape()
                .stroke(CairnColor.lavenderStone.opacity(0.75), lineWidth: 1.5)
                .frame(height: 56)
                .offset(y: 14)

            Image("CairnHeroArtwork")
                .resizable()
                .scaledToFit()
                .frame(width: 124, height: 124)
                .offset(y: -4)
        }
        .frame(height: 104)
    }
}

private struct GroundShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.midY + 12))
        path.addCurve(
            to: CGPoint(x: rect.maxX, y: rect.midY - 6),
            control1: CGPoint(x: rect.width * 0.25, y: rect.midY - 34),
            control2: CGPoint(x: rect.width * 0.72, y: rect.midY + 18)
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

private struct GroundLineShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX + 12, y: rect.midY + 18))
        path.addCurve(
            to: CGPoint(x: rect.maxX - 12, y: rect.midY + 4),
            control1: CGPoint(x: rect.width * 0.30, y: rect.midY - 18),
            control2: CGPoint(x: rect.width * 0.66, y: rect.midY + 28)
        )
        return path
    }
}

private struct DashboardSectionTitle: View {
    let title: String
    let subtitle: String?

    init(title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
            Text(title)
                .font(.headline.weight(.semibold))
                .foregroundStyle(CairnColor.textPrimary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct DashboardContentSection<Content: View>: View {
    let title: String
    let subtitle: String?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            DashboardSectionTitle(title: title, subtitle: subtitle)
            content()
        }
        .padding(CairnSpacing.large)
        .background(CairnColor.lavenderSurface)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}
