//
//  RecurringTransactionDetailView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct RecurringTransactionDetailView: View {
    let recurringTransaction: RecurringTransaction
    let accountName: String
    let nextOccurrence: Date?
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        List {
            VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                Text("Recurring \(recurringTransaction.direction.displayName.lowercased())")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(recurringTransaction.direction == .inflow ? CairnColor.positive : CairnColor.negative)

                Text(RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount))
                    .cairnHeroAmount()
                    .foregroundStyle(CairnColor.textPrimary)

                Text(accountName)
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, CairnSpacing.large)
            .listRowInsets(EdgeInsets(
                top: CairnSpacing.large,
                leading: CairnSpacing.extraLarge,
                bottom: CairnSpacing.medium,
                trailing: CairnSpacing.extraLarge
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(CairnColor.canvas)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("Recurring \(recurringTransaction.direction.displayName.lowercased()), \(RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount)), \(accountName)")

            Section("Schedule") {
                LabeledContent("Frequency", value: recurringTransaction.frequency.displayName)

                if let nextOccurrence {
                    LabeledContent("Next Occurrence", value: RecurringTransactionDateFormatter.dateTime(nextOccurrence))
                } else {
                    LabeledContent("Next Occurrence", value: "No next occurrence")
                }
            }

            Section("Dates") {
                LabeledContent("Start Date", value: RecurringTransactionDateFormatter.dateTime(recurringTransaction.startDate))

                if let endDate = recurringTransaction.endDate {
                    LabeledContent("End Date", value: RecurringTransactionDateFormatter.dateTime(endDate))
                } else {
                    LabeledContent("End Date", value: "None")
                }
            }

            if let memo = recurringTransaction.memo {
                Section("Memo") {
                    Text(memo)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Section {
                Button("Delete Recurring Transaction", role: .destructive, action: delete)
                    .accessibilityLabel("Delete \(recurringTransaction.frequency.displayName.lowercased()) \(recurringTransaction.direction.displayName.lowercased()) \(RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount)) for \(accountName)")
            }
        }
        .scrollContentBackground(.hidden)
        .background(CairnColor.canvas)
        .navigationTitle("Recurring Transaction")
        .tint(CairnColor.plum)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
            }
        }
    }
}
