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
            Section("Recurring Transaction") {
                LabeledContent("Amount", value: RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount))
                LabeledContent("Direction", value: recurringTransaction.direction.displayName)
                LabeledContent("Frequency", value: recurringTransaction.frequency.displayName)
            }

            Section("Account") {
                LabeledContent("Account", value: accountName)
            }

            Section("Schedule") {
                LabeledContent("Start Date", value: RecurringTransactionDateFormatter.dateTime(recurringTransaction.startDate))

                if let endDate = recurringTransaction.endDate {
                    LabeledContent("End Date", value: RecurringTransactionDateFormatter.dateTime(endDate))
                } else {
                    LabeledContent("End Date", value: "None")
                }

                if let nextOccurrence {
                    LabeledContent("Next Occurrence", value: RecurringTransactionDateFormatter.dateTime(nextOccurrence))
                } else {
                    LabeledContent("Next Occurrence", value: "None")
                }
            }

            if let memo = recurringTransaction.memo {
                Section("Memo") {
                    Text(memo)
                }
            }

            Section {
                Button("Delete Recurring Transaction", role: .destructive, action: delete)
                    .accessibilityLabel("Delete Recurring Transaction")
            }
        }
        .navigationTitle("Recurring Transaction")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
            }
        }
    }
}
