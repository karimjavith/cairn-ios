//
//  BudgetPresentationFormattingTests.swift
//  CairnTests
//
//  Created by Codex on 23/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct BudgetPresentationFormattingTests {
    @Test func positiveBudgetRemainderUsesRemainingStatus() throws {
        let remaining = try Money(amount: 25, currencyCode: "GBP")

        #expect(BudgetMoneyFormatter.remainingStatusTitle(remaining) == "Remaining")
        #expect(BudgetMoneyFormatter.remainingStatusAccessibilityText(remaining).contains("remaining"))
        #expect(BudgetMoneyFormatter.remainingStatusAccessibilityText(remaining).contains("-") == false)
    }

    @Test func negativeBudgetRemainderUsesOverspentStatusWithoutColorDependency() throws {
        let remaining = try Money(amount: -25, currencyCode: "GBP")

        #expect(BudgetMoneyFormatter.remainingStatusTitle(remaining) == "Overspent")
        #expect(BudgetMoneyFormatter.remainingStatusAccessibilityText(remaining).contains("overspent by"))
        #expect(BudgetMoneyFormatter.remainingStatusAccessibilityText(remaining).contains("-") == false)
    }

    @Test func dashboardBudgetRemainderUsesSameOverspentSemantics() throws {
        let remaining = try Money(amount: -10, currencyCode: "GBP")

        #expect(DashboardMoneyFormatter.remainingStatusTitle(remaining) == "Overspent")
        #expect(DashboardMoneyFormatter.remainingStatusValue(remaining).contains("-") == false)
    }

    @Test func normalBudgetProgressUsesRemainingTextAndPrimaryIntent() throws {
        let presentation = try makePresentation(spent: 40, limit: 100, remaining: 60)

        #expect(presentation.status == .normal)
        #expect(presentation.valueText.contains("remaining"))
        #expect(presentation.detailText.contains("spent of"))
        #expect(presentation.accessibilityLabel.contains("in progress"))
        #expect(presentation.visibleFraction == 0.4)
        #expect(presentation.valueColorIntent == .primary)
        #expect(presentation.progressColorIntent == .primary)
    }

    @Test func nearLimitStartsAtEightyPercentWithPrimaryValueAndWarningProgressIntent() throws {
        let presentation = try makePresentation(spent: 80, limit: 100, remaining: 20)

        #expect(presentation.status == .nearLimit)
        #expect(presentation.valueText.contains("remaining"))
        #expect(presentation.accessibilityLabel.contains("near limit"))
        #expect(presentation.visibleFraction == 0.8)
        #expect(presentation.valueColorIntent == .primary)
        #expect(presentation.progressColorIntent == .warning)
    }

    @Test func belowNearLimitThresholdRemainsNormal() throws {
        let presentation = try makePresentation(spent: 79.99, limit: 100, remaining: 20.01)

        #expect(presentation.status == .normal)
        #expect(presentation.visibleFraction < 0.8)
    }

    @Test func fullySpentBudgetUsesTextStatusAndFullProgress() throws {
        let presentation = try makePresentation(spent: 100, limit: 100, remaining: 0)

        #expect(presentation.status == .fullySpent)
        #expect(presentation.valueText == "Fully spent")
        #expect(presentation.accessibilityLabel.contains("fully spent"))
        #expect(presentation.visibleFraction == 1)
        #expect(presentation.valueColorIntent == .warning)
        #expect(presentation.progressColorIntent == .warning)
    }

    @Test func overspentBudgetUsesAbsoluteAmountAndClampedProgress() throws {
        let presentation = try makePresentation(spent: 125, limit: 100, remaining: -25)

        #expect(presentation.status == .overspent)
        #expect(presentation.valueText.contains("Overspent by"))
        #expect(presentation.valueText.contains("-") == false)
        #expect(presentation.accessibilityLabel.contains("overspent"))
        #expect(presentation.visibleFraction == 1)
        #expect(presentation.valueColorIntent == .negative)
        #expect(presentation.progressColorIntent == .warning)
    }

    @Test func progressIsClampedToZeroForNegativeSpentInput() throws {
        let presentation = try makePresentation(spent: -10, limit: 100, remaining: 110)

        #expect(presentation.status == .normal)
        #expect(presentation.visibleFraction == 0)
    }

    @Test func zeroLimitWithNoSpendIsFullySpentWithZeroVisualProgress() throws {
        let presentation = try makePresentation(spent: 0, limit: 0, remaining: 0)

        #expect(presentation.status == .fullySpent)
        #expect(presentation.valueText == "Fully spent")
        #expect(presentation.accessibilityLabel.contains("fully spent"))
        #expect(presentation.visibleFraction == 0)
    }

    @Test func zeroLimitWithSpendIsOverspentWithFullVisualProgress() throws {
        let presentation = try makePresentation(spent: 25, limit: 0, remaining: -25)

        #expect(presentation.status == .overspent)
        #expect(presentation.valueText.contains("Overspent by"))
        #expect(presentation.valueText.contains("-") == false)
        #expect(presentation.accessibilityLabel.contains("overspent"))
        #expect(presentation.visibleFraction == 1)
    }

    @Test func zeroLimitOverspentAmountUsesSpentWhenRemainingIsNotNegative() throws {
        let spent = try Money(amount: 25, currencyCode: "GBP")
        let presentation = try makePresentation(spent: spent.amount, limit: 0, remaining: 0)

        #expect(presentation.status == .overspent)
        #expect(presentation.valueText.contains(BudgetMoneyFormatter.currency(spent)))
        #expect(presentation.visibleFraction == 1)
    }

    private func makePresentation(
        spent: Decimal,
        limit: Decimal,
        remaining: Decimal
    ) throws -> BudgetProgressPresentation {
        let budget = try Budget(
            categoryID: CategoryID(),
            limit: Money(amount: limit, currencyCode: "GBP"),
            period: BudgetPeriod(
                startDate: Date(timeIntervalSince1970: 1_786_080_000),
                endDate: Date(timeIntervalSince1970: 1_788_672_000)
            )
        )
        let progress = BudgetProgress(
            budget: budget,
            spent: try Money(amount: spent, currencyCode: "GBP"),
            remaining: try Money(amount: remaining, currencyCode: "GBP")
        )

        return BudgetProgressPresentation.make(
            categoryName: "Groceries",
            progress: progress
        )
    }
}
