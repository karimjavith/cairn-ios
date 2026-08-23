//
//  CairnStyleReferenceView.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

#if DEBUG
import SwiftUI

struct CairnStyleReferenceView: View {
    private let balance = try? Money(amount: 4820.75, currencyCode: "GBP")
    private let spent = try? Money(amount: 620, currencyCode: "GBP")
    private let limit = try? Money(amount: 500, currencyCode: "GBP")
    private let remaining = try? Money(amount: -120, currencyCode: "GBP")
    private let saved = try? Money(amount: 850, currencyCode: "GBP")
    private let target = try? Money(amount: 1000, currencyCode: "GBP")

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: CairnSpacing.section) {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Net Worth")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text(balance.map(CairnMoneyPresentation.currency) ?? "£0.00")
                        .cairnHeroAmount()

                    Text("Across active accounts")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                    CairnSectionHeading("Recent activity", subtitle: "Financial rows prioritize identity and amount.")

                    CairnFinancialRow(
                        title: "Coffee",
                        metadata: "Food and drink · Today",
                        trailing: "£4.20",
                        status: "Outflow",
                        accessibilityLabel: "Coffee, Food and drink, Today, outflow 4 pounds 20"
                    ) {
                        Image(systemName: "cup.and.saucer")
                            .foregroundStyle(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                    CairnSectionHeading("Progress")

                    if let spent, let limit, let remaining {
                        CairnProgressSummaryView(
                            presentation: .budget(
                                title: "Groceries",
                                spent: spent,
                                limit: limit,
                                remaining: remaining
                            )
                        )
                        .cairnSurface()
                    }

                    if let saved, let target {
                        CairnProgressSummaryView(
                            presentation: .goal(
                                title: "Emergency fund",
                                saved: saved,
                                target: target,
                                ratio: 0.85
                            )
                        )
                        .cairnSurface()
                    }
                }

                CairnEmptyStateView(
                    title: "No transactions yet",
                    message: "Add your first transaction to start building a clear picture of cash flow.",
                    systemImage: "arrow.left.arrow.right",
                    actionLabel: "Add Transaction",
                    action: {}
                )
                .cairnSurface()

                Button("Primary Action") {}
                    .buttonStyle(.borderedProminent)
            }
            .padding(CairnSpacing.large)
        }
        .background(Color(.systemBackground))
    }
}

#Preview("Cairn Style Reference") {
    CairnStyleReferenceView()
}
#endif
