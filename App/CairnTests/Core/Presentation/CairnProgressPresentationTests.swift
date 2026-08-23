//
//  CairnProgressPresentationTests.swift
//  CairnTests
//
//  Created by Codex on 23/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct CairnProgressPresentationTests {
    @Test func budgetOverspendingUsesTextualStatusAndAbsoluteAmount() throws {
        let spent = try Money(amount: 620, currencyCode: "GBP")
        let limit = try Money(amount: 500, currencyCode: "GBP")
        let remaining = try Money(amount: -120, currencyCode: "GBP")

        let presentation = CairnProgressPresentation.budget(
            title: "Groceries",
            spent: spent,
            limit: limit,
            remaining: remaining
        )

        #expect(presentation.status == .overspent)
        #expect(presentation.valueText.contains("Overspent by"))
        #expect(presentation.valueText.contains("-") == false)
        #expect(presentation.accessibilityLabel.contains("overspent by"))
        #expect(presentation.visibleFraction == 1)
    }

    @Test func budgetRemainingUsesTextualRemainingStatus() throws {
        let spent = try Money(amount: 300, currencyCode: "GBP")
        let limit = try Money(amount: 500, currencyCode: "GBP")
        let remaining = try Money(amount: 200, currencyCode: "GBP")

        let presentation = CairnProgressPresentation.budget(
            title: "Groceries",
            spent: spent,
            limit: limit,
            remaining: remaining
        )

        #expect(presentation.status == .inProgress)
        #expect(presentation.valueText.contains("remaining"))
        #expect(presentation.accessibilityLabel.contains("remaining"))
        #expect(presentation.visibleFraction == 0.6)
    }

    @Test func completedGoalUsesCompletionTextNotColorOnly() throws {
        let saved = try Money(amount: 1000, currencyCode: "GBP")
        let target = try Money(amount: 1000, currencyCode: "GBP")

        let presentation = CairnProgressPresentation.goal(
            title: "Emergency fund",
            saved: saved,
            target: target,
            ratio: 1
        )

        #expect(presentation.status == .complete)
        #expect(presentation.valueText == "Complete")
        #expect(presentation.accessibilityLabel.contains("complete"))
        #expect(presentation.visibleFraction == 1)
    }

    @Test func goalPercentageFormatsZeroWithoutUnnecessaryDecimals() {
        #expect(CairnProgressPresentation.percentText(0, locale: Locale(identifier: "en_US")) == "0%")
    }

    @Test func goalPercentageFormatsHalfWithoutUnnecessaryDecimals() {
        #expect(CairnProgressPresentation.percentText(0.5, locale: Locale(identifier: "en_US")) == "50%")
    }

    @Test func goalPercentageFormatsOneWithoutUnnecessaryDecimals() {
        #expect(CairnProgressPresentation.percentText(1, locale: Locale(identifier: "en_US")) == "100%")
    }

    @Test func goalPercentageFormatsOneThirdWithBoundedPrecision() {
        let ratio = Decimal(1) / Decimal(3)
        let text = CairnProgressPresentation.percentText(ratio, locale: Locale(identifier: "en_US"))

        #expect(text == "33.3%")
        #expect(text.count < 8)
    }

    @Test func goalPercentageFormatsTwoThirdsWithBoundedPrecision() {
        let ratio = Decimal(2) / Decimal(3)
        let text = CairnProgressPresentation.percentText(ratio, locale: Locale(identifier: "en_US"))

        #expect(text == "66.7%")
        #expect(text.count < 8)
    }

    @Test func goalOvershootKeepsCompletionSemantics() throws {
        let saved = try Money(amount: 1250, currencyCode: "GBP")
        let target = try Money(amount: 1000, currencyCode: "GBP")

        let presentation = CairnProgressPresentation.goal(
            title: "Emergency fund",
            saved: saved,
            target: target,
            ratio: 1.25,
            locale: Locale(identifier: "en_US")
        )

        #expect(presentation.status == .complete)
        #expect(presentation.valueText == "Complete")
        #expect(presentation.accessibilityLabel.contains("complete"))
        #expect(presentation.visibleFraction == 1)
    }

    @Test func goalPercentageRespectsCommaDecimalLocale() {
        let ratio = Decimal(1) / Decimal(3)
        let text = CairnProgressPresentation.percentText(ratio, locale: Locale(identifier: "fr_FR"))

        #expect(text.contains("33,3"))
        #expect(text.contains("33.3") == false)
        #expect(text.count < 10)
    }
}
