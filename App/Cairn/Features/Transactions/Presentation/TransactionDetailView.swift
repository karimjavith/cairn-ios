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
        List {
            Section("Transaction") {
                LabeledContent("Amount", value: TransactionMoneyFormatter.currency(transaction.amount))
                LabeledContent("Direction", value: transaction.direction.displayName)
                LabeledContent("Date", value: TransactionDateFormatter.dateTime(transaction.occurredAt))
            }

            Section("Account") {
                LabeledContent("Account", value: accountName)
            }

            Section("Category") {
                LabeledContent("Category", value: categoryName)
            }

            if let memo = transaction.memo {
                Section("Memo") {
                    Text(memo)
                }
            }

            Section {
                Button("Delete Transaction", role: .destructive, action: delete)
                    .accessibilityLabel("Delete Transaction")
            }
        }
        .navigationTitle("Transaction")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
            }
        }
    }
}
