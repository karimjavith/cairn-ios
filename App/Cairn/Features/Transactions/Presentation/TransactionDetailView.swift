//
//  TransactionDetailView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct TransactionDetailView: View {
    let transaction: Transaction
    let accountName: String
    let categoryName: String
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CairnSpacing.section) {
                    header

                    VStack(alignment: .leading, spacing: CairnSpacing.large) {
                        detailSection("Details") {
                            detailRow(title: "Account", value: accountName)
                            detailRow(title: "Category", value: categoryName)
                        }

                        if let memo = transaction.memo {
                            detailSection("Memo") {
                                Text(memo)
                                    .font(.body)
                                    .foregroundStyle(CairnColor.textPrimary)
                                    .fixedSize(horizontal: false, vertical: true)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, CairnSpacing.small)
                            }
                        }

                        Button("Delete Transaction", role: .destructive, action: delete)
                            .accessibilityLabel("Delete \(transaction.direction.displayName.lowercased()) \(CairnMoneyPresentation.currency(transaction.amount)) from \(accountName) on \(TransactionDateFormatter.dateTime(transaction.occurredAt))")
                            .padding(.top, CairnSpacing.small)
                    }
                }
                .padding(.horizontal, CairnSpacing.extraLarge)
                .padding(.top, CairnSpacing.large)
                .padding(.bottom, CairnSpacing.section)
            }
        }
        .navigationTitle("Transaction")
        .tint(CairnColor.plum)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
            }
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            Text(transaction.direction.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(transaction.direction == .inflow ? CairnColor.positive : CairnColor.negative)

            Text(TransactionListPresentation.signedAmountText(transaction))
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .foregroundStyle(transaction.direction == .inflow ? CairnColor.positive : CairnColor.negative)

            Text(TransactionDateFormatter.dateTime(transaction.occurredAt))
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)

            Text(accountName)
                .font(.body.weight(.medium))
                .foregroundStyle(CairnColor.textPrimary)
        }
        .accessibilityElement(children: .combine)
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
