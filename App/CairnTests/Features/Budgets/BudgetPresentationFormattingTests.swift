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
}
