//
//  TransactionsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct TransactionsView: View {
    @State private var store: TransactionsStore

    init(
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        createTransaction: CreateTransaction
    ) {
        _store = State(wrappedValue: TransactionsStore(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
            createTransaction: createTransaction
        ))
    }

    var body: some View {
        @Bindable var store = store

        Group {
            if store.isLoading {
                ProgressView("Loading transactions")
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Transactions Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadTransactions()
                        }
                    }
                )
            } else if store.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "list.bullet.rectangle",
                    description: Text("Add your first transaction to start tracking activity.")
                )
            } else {
                transactionList
            }
        }
        .navigationTitle("Transactions")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startCreateTransaction()
                } label: {
                    Label("Add Transaction", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let errorMessage = store.errorMessage, !store.hasLoadFailed {
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
            TransactionEditorView(
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
            "Delete Transaction?",
            isPresented: Binding(
                get: { store.pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelDelete()
                    }
                }
            ),
            presenting: store.pendingDeletion
        ) { transaction in
            Button("Delete Transaction", role: .destructive) {
                Task {
                    await store.confirmDelete(transaction)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { transaction in
            Text("This cannot be undone.")
        }
        .navigationDestination(item: $store.route) { route in
            switch route {
            case let .detail(transactionID):
                if let transaction = store.transaction(id: transactionID) {
                    TransactionDetailView(
                        transaction: transaction,
                        accountName: store.accountName(for: transaction.accountID),
                        categoryName: store.categoryName(for: transaction.categoryID),
                        edit: { store.startEditing(transaction) },
                        delete: { store.requestDelete(transaction) }
                    )
                } else {
                    ContentUnavailableView(
                        "Transaction Not Found",
                        systemImage: "questionmark.folder",
                        description: Text("The selected transaction is no longer available.")
                    )
                }
            }
        }
        .task {
            await store.loadTransactions()
        }
    }

    private var transactionList: some View {
        List(store.transactions, id: \.id) { transaction in
            Button {
                store.selectDetail(transactionID: transaction.id)
            } label: {
                TransactionRowView(
                    transaction: transaction,
                    accountName: store.accountName(for: transaction.accountID),
                    categoryName: store.categoryName(for: transaction.categoryID)
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: transaction))
            .swipeActions {
                Button(role: .destructive) {
                    store.requestDelete(transaction)
                } label: {
                    Label("Delete Transaction", systemImage: "trash")
                }
                .accessibilityLabel("Delete Transaction")
            }
        }
    }

    private func accessibilityLabel(for transaction: Transaction) -> String {
        let amount = TransactionMoneyFormatter.currency(transaction.amount)
        let accountName = store.accountName(for: transaction.accountID)
        let categoryName = store.categoryName(for: transaction.categoryID)
        let memo = transaction.memo.map { ", \($0)" } ?? ""

        return "\(transaction.direction.displayName), \(amount), \(accountName), \(categoryName), \(TransactionDateFormatter.dateTime(transaction.occurredAt))\(memo)"
    }
}

private struct TransactionRowView: View {
    let transaction: Transaction
    let accountName: String
    let categoryName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(transaction.direction.displayName)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(accountName)
                        .font(.body)
                }

                Spacer(minLength: 16)

                Text(TransactionMoneyFormatter.currency(transaction.amount))
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.trailing)
            }

            Text("\(TransactionDateFormatter.dateTime(transaction.occurredAt)) - \(categoryName)")
                .font(.footnote)
                .foregroundStyle(.secondary)

            if let memo = transaction.memo {
                Text(memo)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
        }
        .contentShape(Rectangle())
    }
}
