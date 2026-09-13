//
//  TransactionsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct TransactionsView: View {
    @State private var store: TransactionsStore
    let startAccountCreation: () -> Void

    init(
        transactionRepository: any TransactionRepository,
        accountRepository: any AccountRepository,
        categoryRepository: any CategoryRepository,
        createTransaction: CreateTransaction,
        startAccountCreation: @escaping () -> Void = {}
    ) {
        self.startAccountCreation = startAccountCreation
        _store = State(wrappedValue: TransactionsStore(
            transactionRepository: transactionRepository,
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
            createTransaction: createTransaction
        ))
    }

    var body: some View {
        @Bindable var store = store

        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            if store.isLoading {
                ProgressView("Loading transactions")
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                VStack {
                    LoadFailureView(
                        title: "Transactions Unavailable",
                        message: errorMessage,
                        retry: {
                            Task {
                                await store.loadTransactions()
                            }
                        }
                    )
                }
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else if store.needsAccountBeforeTransaction {
                noAccountView
            } else if store.isEmpty {
                emptyTransactionsView
            } else {
                transactionsContent
            }
        }
        .navigationTitle("Transactions")
        .tint(CairnColor.plum)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if store.accounts.isEmpty {
                    Button {
                        startAccountCreation()
                    } label: {
                        Label("Add Account", systemImage: "plus")
                    }
                } else {
                    Button {
                        store.startCreateTransaction()
                    } label: {
                        Label("Add Transaction", systemImage: "plus")
                    }
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
            Text("This deletes \(deleteContext(for: transaction)). This cannot be undone.")
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

    private var noAccountView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "Add an account first",
                message: "Transactions need an account before they can be recorded.",
                systemImage: "creditcard",
                actionLabel: "Add account",
                action: startAccountCreation
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
        .scrollContentBackground(.hidden)
    }

    private var emptyTransactionsView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "No transactions yet",
                message: "Add your first transaction to start building your activity history.",
                systemImage: "list.bullet.rectangle",
                actionLabel: "Add transaction",
                action: { store.startCreateTransaction() }
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
        .scrollContentBackground(.hidden)
    }

    private var transactionsContent: some View {
        List {
            ForEach(Array(transactionSections.enumerated()), id: \.offset) { index, section in
                CairnSectionHeading(section.title)
                    .listRowInsets(EdgeInsets(
                        top: index == 0 ? CairnSpacing.large : CairnSpacing.section,
                        leading: CairnSpacing.extraLarge,
                        bottom: CairnSpacing.medium,
                        trailing: CairnSpacing.extraLarge
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(CairnColor.canvas)

                ForEach(section.transactions, id: \.id) { transaction in
                    Button {
                        store.selectDetail(transactionID: transaction.id)
                    } label: {
                        TransactionRowView(
                            presentation: rowPresentation(for: transaction),
                            direction: transaction.direction
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(rowPresentation(for: transaction).accessibilityLabel)
                    .swipeActions {
                        Button(role: .destructive) {
                            store.requestDelete(transaction)
                        } label: {
                            Label("Delete Transaction", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete Transaction")
                    }
                    .contextMenu {
                        Button(role: .destructive) {
                            store.requestDelete(transaction)
                        } label: {
                            Label("Delete Transaction", systemImage: "trash")
                        }
                    }
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: CairnSpacing.extraLarge,
                        bottom: 0,
                        trailing: CairnSpacing.extraLarge
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(CairnColor.canvas)

                    if transaction.id != section.transactions.last?.id {
                        Divider()
                            .overlay(CairnColor.separator)
                            .listRowInsets(EdgeInsets(
                                top: 0,
                                leading: CairnSpacing.extraLarge,
                                bottom: 0,
                                trailing: CairnSpacing.extraLarge
                            ))
                            .listRowSeparator(.hidden)
                            .listRowBackground(CairnColor.canvas)
                    }
                }
            }

            Color.clear
                .frame(height: CairnSpacing.section)
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .listRowBackground(CairnColor.canvas)
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .background(CairnColor.canvas)
    }

    private var transactionSections: [TransactionDaySection] {
        TransactionListPresentation.sections(transactions: store.transactions)
    }

    private func rowPresentation(for transaction: Transaction) -> TransactionRowPresentation {
        TransactionListPresentation.row(
            transaction: transaction,
            accountName: store.accountName(for: transaction.accountID),
            categoryName: store.categoryName(for: transaction.categoryID)
        )
    }

    private func deleteContext(for transaction: Transaction) -> String {
        "\(transaction.direction.displayName.lowercased()) \(CairnMoneyPresentation.currency(transaction.amount)) from \(store.accountName(for: transaction.accountID)) on \(TransactionDateFormatter.dateTime(transaction.occurredAt))"
    }
}

private struct TransactionRowView: View {
    let presentation: TransactionRowPresentation
    let direction: TransactionDirection

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            Image(systemName: direction == .inflow ? "arrow.down.left" : "arrow.up.right")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(direction == .inflow ? CairnColor.positive : CairnColor.negative)
                .frame(width: 28, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
                Text(presentation.title)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CairnColor.textPrimary)
                    .lineLimit(2)

                Text(presentation.metadata)
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
                    .lineLimit(1)
            }

            Spacer(minLength: CairnSpacing.medium)

            VStack(alignment: .trailing, spacing: CairnSpacing.extraSmall) {
                Text(presentation.amountText)
                    .cairnRowAmount()
                    .foregroundStyle(direction == .inflow ? CairnColor.positive : CairnColor.negative)

                Text(presentation.timeText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CairnColor.textSecondary)
            }
        }
        .padding(.vertical, CairnSpacing.small)
        .contentShape(Rectangle())
    }
}
