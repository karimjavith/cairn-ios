//
//  BudgetDetailView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget
    let progress: BudgetProgress
    let categoryName: String
    let edit: () -> Void
    let delete: () -> Void

    private var presentation: BudgetProgressPresentation {
        BudgetProgressPresentation.make(
            categoryName: categoryName,
            progress: progress
        )
    }

    var body: some View {
        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CairnSpacing.section) {
                    header

                    VStack(alignment: .leading, spacing: CairnSpacing.large) {
                        detailSection("Progress") {
                            detailRow(title: "Spent", value: BudgetMoneyFormatter.currency(progress.spent))
                            detailRow(title: "Limit", value: BudgetMoneyFormatter.currency(budget.limit))
                            detailRow(title: statusDetailTitle, value: statusDetailValue)
                        }

                        detailSection("Budget") {
                            detailRow(title: "Category", value: categoryName)
                            detailRow(title: "Period", value: BudgetDateFormatter.period(budget.period))
                        }

                        Button("Delete \(categoryName) Budget", role: .destructive, action: delete)
                            .accessibilityLabel("Delete \(categoryName) Budget")
                            .padding(.top, CairnSpacing.small)
                    }
                }
                .padding(.horizontal, CairnSpacing.extraLarge)
                .padding(.top, CairnSpacing.large)
                .padding(.bottom, CairnSpacing.section)
            }
        }
        .navigationTitle("Budget")
        .tint(CairnColor.plum)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
                    .accessibilityLabel("Edit \(categoryName) Budget")
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            Text(categoryName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CairnColor.plum)

            Text(heroValueText)
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .foregroundStyle(presentation.detailValueColor)

            Text(heroStatusText)
                .font(.body.weight(.semibold))
                .foregroundStyle(presentation.detailValueColor)
                .fixedSize(horizontal: false, vertical: true)

            ProgressView(value: presentation.visibleFraction)
                .tint(presentation.detailProgressColor)
                .accessibilityHidden(true)

            Text(presentation.detailText)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel)
    }

    private var heroValueText: String {
        switch presentation.status {
        case .normal, .nearLimit, .fullySpent:
            BudgetMoneyFormatter.currency(progress.remaining)
        case .overspent:
            overspentHeroAmountText
        }
    }

    private var overspentHeroAmountText: String {
        if progress.remaining.amount < 0 {
            return BudgetMoneyFormatter.remainingStatusValue(progress.remaining)
        }

        return BudgetMoneyFormatter.currency(progress.spent)
    }

    private var heroStatusText: String {
        switch presentation.status {
        case .normal:
            "Remaining"
        case .nearLimit:
            "Near limit"
        case .fullySpent:
            "Fully spent"
        case .overspent:
            "Overspent"
        }
    }

    private var statusDetailTitle: String {
        switch presentation.status {
        case .overspent:
            "Overspent"
        case .fullySpent:
            "Status"
        case .normal, .nearLimit:
            "Remaining"
        }
    }

    private var statusDetailValue: String {
        switch presentation.status {
        case .fullySpent:
            "Fully spent"
        case .overspent:
            BudgetMoneyFormatter.remainingStatusValue(progress.remaining)
        case .normal, .nearLimit:
            BudgetMoneyFormatter.currency(progress.remaining)
        }
    }

    private func detailSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            CairnSectionHeading(title)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)

            Spacer(minLength: CairnSpacing.large)

            Text(value)
                .font(.body.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(CairnColor.textPrimary)
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, CairnSpacing.small)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(CairnColor.separator)
        }
    }
}

private extension BudgetProgressPresentation {
    var detailValueColor: Color {
        switch valueColorIntent {
        case .primary:
            CairnColor.textPrimary
        case .warning:
            CairnColor.warning
        case .negative:
            CairnColor.negative
        }
    }

    var detailProgressColor: Color {
        switch progressColorIntent {
        case .primary:
            CairnColor.plum
        case .warning:
            CairnColor.warning
        case .negative:
            CairnColor.negative
        }
    }
}
