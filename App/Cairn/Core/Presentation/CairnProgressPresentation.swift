//
//  CairnProgressPresentation.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import Foundation
import SwiftUI

enum CairnProgressStatus: String, Sendable {
    case inProgress = "In progress"
    case complete = "Complete"
    case overspent = "Overspent"
}

struct CairnProgressPresentation: Equatable, Sendable {
    let title: String
    let valueText: String
    let detailText: String
    let accessibilityLabel: String
    let visibleFraction: Double
    let status: CairnProgressStatus

    nonisolated static func budget(
        title: String,
        spent: Money,
        limit: Money,
        remaining: Money
    ) -> CairnProgressPresentation {
        let spentText = CairnMoneyPresentation.currency(spent)
        let limitText = CairnMoneyPresentation.currency(limit)
        let isOverspent = remaining.amount < 0
        let remainingText = CairnMoneyPresentation.absoluteCurrency(remaining)
        let ratio = progressRatio(completed: spent.amount, target: limit.amount)

        return CairnProgressPresentation(
            title: title,
            valueText: isOverspent ? "Overspent by \(remainingText)" : "\(remainingText) remaining",
            detailText: "\(spentText) spent of \(limitText)",
            accessibilityLabel: isOverspent
                ? "\(title), overspent by \(remainingText), \(spentText) spent of \(limitText)"
                : "\(title), \(remainingText) remaining, \(spentText) spent of \(limitText)",
            visibleFraction: ratio,
            status: isOverspent ? .overspent : .inProgress
        )
    }

    nonisolated static func goal(
        title: String,
        saved: Money,
        target: Money,
        ratio: Decimal,
        locale: Locale = .current
    ) -> CairnProgressPresentation {
        let savedText = CairnMoneyPresentation.currency(saved)
        let targetText = CairnMoneyPresentation.currency(target)
        let percentText = percent(ratio, locale: locale)
        let isComplete = ratio >= 1

        return CairnProgressPresentation(
            title: title,
            valueText: isComplete ? "Complete" : percentText,
            detailText: "\(savedText) saved of \(targetText)",
            accessibilityLabel: "\(title), \(isComplete ? "complete" : percentText), \(savedText) saved of \(targetText)",
            visibleFraction: clampedDouble(ratio),
            status: isComplete ? .complete : .inProgress
        )
    }

    nonisolated private static func progressRatio(completed: Decimal, target: Decimal) -> Double {
        guard target > 0 else {
            return 0
        }

        return clampedDouble(completed / target)
    }

    nonisolated private static func clampedDouble(_ ratio: Decimal) -> Double {
        let value = NSDecimalNumber(decimal: ratio).doubleValue

        guard value.isFinite else {
            return 0
        }

        return min(max(value, 0), 1)
    }

    nonisolated static func percentText(_ ratio: Decimal, locale: Locale = .current) -> String {
        percent(ratio, locale: locale)
    }

    nonisolated private static func percent(_ ratio: Decimal, locale: Locale) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.locale = locale
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = 1
        formatter.roundingMode = .halfUp

        return formatter.string(from: NSDecimalNumber(decimal: ratio))
            ?? "0%"
    }
}

struct CairnProgressSummaryView: View {
    let presentation: CairnProgressPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(presentation.title)
                    .font(.subheadline.weight(.semibold))

                Spacer(minLength: CairnSpacing.medium)

                Text(presentation.valueText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
            }

            ProgressView(value: presentation.visibleFraction)
                .tint(tint)

            Text(presentation.detailText)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    private var tint: Color {
        switch presentation.status {
        case .inProgress:
            .accentColor
        case .complete:
            .green
        case .overspent:
            .orange
        }
    }
}
