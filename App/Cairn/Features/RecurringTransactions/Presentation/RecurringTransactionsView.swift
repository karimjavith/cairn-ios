//
//  RecurringTransactionsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import SwiftUI

struct RecurringTransactionsView: View {
    @State private var store: RecurringTransactionsStore

    init(
        recurringTransactionRepository: any RecurringTransactionRepository,
        accountRepository: any AccountRepository,
        calendar: Calendar
    ) {
        _store = State(wrappedValue: RecurringTransactionsStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: accountRepository,
            calendar: calendar
        ))
    }

    var body: some View {
        @Bindable var store = store

        Group {
            if store.isLoading {
                ProgressView("Loading recurring transactions")
            } else if store.isEmpty {
                ContentUnavailableView(
                    "No Recurring Transactions",
                    systemImage: "repeat",
                    description: Text("Add your first recurring transaction to track repeated activity.")
                )
            } else {
                recurringTransactionList
            }
        }
        .navigationTitle("Recurring Transactions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startCreateRecurringTransaction()
                } label: {
                    Label("Add Recurring Transaction", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.bar)
                    .accessibilityLabel(errorMessage)
            }
        }
        .sheet(item: $store.editor) { editor in
            RecurringTransactionEditorView(
                editor: editor,
                cancel: { store.dismissEditor() },
                save: {
                    Task {
                        await store.saveEditor()
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete Recurring Transaction?",
            isPresented: Binding(
                get: { store.pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelDelete()
                    }
                }
            ),
            presenting: store.pendingDeletion
        ) { recurringTransaction in
            Button("Delete Recurring Transaction", role: .destructive) {
                Task {
                    await store.confirmDelete(recurringTransaction)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { recurringTransaction in
            Text("This cannot be undone.")
        }
        .navigationDestination(item: $store.route) { route in
            switch route {
            case let .detail(recurringTransactionID):
                if let recurringTransaction = store.recurringTransaction(id: recurringTransactionID) {
                    RecurringTransactionDetailView(
                        recurringTransaction: recurringTransaction,
                        accountName: store.accountName(for: recurringTransaction.accountID),
                        nextOccurrence: store.nextOccurrence(for: recurringTransaction.id),
                        edit: { store.startEditing(recurringTransaction) },
                        delete: { store.requestDelete(recurringTransaction) }
                    )
                } else {
                    ContentUnavailableView(
                        "Recurring Transaction Not Found",
                        systemImage: "questionmark.folder",
                        description: Text("The selected recurring transaction is no longer available.")
                    )
                }
            }
        }
        .task {
            await store.loadRecurringTransactions()
        }
    }

    private var recurringTransactionList: some View {
        List(store.recurringTransactions, id: \.id) { recurringTransaction in
            Button {
                store.selectDetail(recurringTransactionID: recurringTransaction.id)
            } label: {
                RecurringTransactionRowView(
                    recurringTransaction: recurringTransaction,
                    accountName: store.accountName(for: recurringTransaction.accountID),
                    nextOccurrence: store.nextOccurrence(for: recurringTransaction.id)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: recurringTransaction))
            .swipeActions {
                Button(role: .destructive) {
                    store.requestDelete(recurringTransaction)
                } label: {
                    Label("Delete Recurring Transaction", systemImage: "trash")
                }
                .accessibilityLabel("Delete Recurring Transaction")
            }
        }
    }

    private func accessibilityLabel(for recurringTransaction: RecurringTransaction) -> String {
        let amount = RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount)
        let accountName = store.accountName(for: recurringTransaction.accountID)
        let nextOccurrenceText = store.nextOccurrence(for: recurringTransaction.id)
            .map { RecurringTransactionDateFormatter.dateTime($0) } ?? "No next occurrence"
        let memo = recurringTransaction.memo.map { ", \($0)" } ?? ""

        return "\(recurringTransaction.direction.displayName), \(amount), \(accountName), \(recurringTransaction.frequency.displayName), next occurrence \(nextOccurrenceText)\(memo)"
    }
}

private struct RecurringTransactionRowView: View {
    let recurringTransaction: RecurringTransaction
    let accountName: String
    let nextOccurrence: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(recurringTransaction.direction.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(accountName)
                        .font(.body)
                }

                Spacer(minLength: 16)

                Text(RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount))
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.trailing)
            }

            Text("\(recurringTransaction.frequency.displayName) from \(RecurringTransactionDateFormatter.dateTime(recurringTransaction.startDate))")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let endDate = recurringTransaction.endDate {
                Text("Ends \(RecurringTransactionDateFormatter.dateTime(endDate))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let nextOccurrence {
                Text("Next \(RecurringTransactionDateFormatter.dateTime(nextOccurrence))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("No next occurrence")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let memo = recurringTransaction.memo {
                Text(memo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
    }
}
