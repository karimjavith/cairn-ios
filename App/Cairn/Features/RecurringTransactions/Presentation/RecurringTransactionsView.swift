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

        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            if store.isLoading {
                ProgressView("Loading recurring transactions")
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Recurring Transactions Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadRecurringTransactions()
                        }
                    }
                )
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else if store.isEmpty {
                emptyRecurringTransactionsView
            } else {
                recurringTransactionList
            }
        }
        .navigationTitle("Recurring Transactions")
        .tint(CairnColor.plum)
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
            if let errorMessage = store.errorMessage, !store.hasLoadFailed {
                Label {
                    Text(errorMessage)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(CairnColor.warning)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .foregroundStyle(CairnColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CairnSpacing.large)
                .background(CairnColor.lavenderSurface)
                .accessibilityElement(children: .ignore)
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
            Text("This deletes \(deleteContext(for: recurringTransaction)). This cannot be undone.")
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

    private var emptyRecurringTransactionsView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "No recurring transactions yet",
                message: "Add a recurring transaction to keep track of scheduled activity.",
                systemImage: "repeat",
                actionLabel: "Add recurring transaction",
                action: { store.startCreateRecurringTransaction() }
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
    }

    private var recurringTransactionList: some View {
        List {
            CairnSectionHeading(
                "Scheduled activity",
                subtitle: store.recurringTransactions.count == 1
                    ? "1 recurring transaction"
                    : "\(store.recurringTransactions.count) recurring transactions"
            )
            .listRowInsets(EdgeInsets(
                top: CairnSpacing.large,
                leading: CairnSpacing.extraLarge,
                bottom: CairnSpacing.medium,
                trailing: CairnSpacing.extraLarge
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(CairnColor.canvas)

            ForEach(store.recurringTransactions, id: \.id) { recurringTransaction in
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
                .listRowInsets(EdgeInsets(
                    top: CairnSpacing.small,
                    leading: CairnSpacing.extraLarge,
                    bottom: CairnSpacing.small,
                    trailing: CairnSpacing.extraLarge
                ))
                .listRowBackground(CairnColor.canvas)
                .swipeActions {
                    Button(role: .destructive) {
                        store.requestDelete(recurringTransaction)
                    } label: {
                        Label("Delete Recurring Transaction", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(deleteContext(for: recurringTransaction))")
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func accessibilityLabel(for recurringTransaction: RecurringTransaction) -> String {
        let amount = RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount)
        let accountName = store.accountName(for: recurringTransaction.accountID)
        let nextOccurrenceText = store.nextOccurrence(for: recurringTransaction.id)
            .map { "Next \(RecurringTransactionDateFormatter.dateTime($0))" } ?? "No next occurrence"
        let endDateText = recurringTransaction.endDate.map {
            ", ends \(RecurringTransactionDateFormatter.dateTime($0))"
        } ?? ""

        let title = recurringTransaction.memo ?? "Recurring transaction"

        return "\(title), \(amount), \(recurringTransaction.direction.displayName), \(accountName), \(recurringTransaction.frequency.displayName), \(nextOccurrenceText), starts \(RecurringTransactionDateFormatter.dateTime(recurringTransaction.startDate))\(endDateText)"
    }

    private func deleteContext(for recurringTransaction: RecurringTransaction) -> String {
        "\(recurringTransaction.frequency.displayName.lowercased()) \(recurringTransaction.direction.displayName.lowercased()) \(RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount)) for \(store.accountName(for: recurringTransaction.accountID))"
    }
}

private struct RecurringTransactionRowView: View {
    let recurringTransaction: RecurringTransaction
    let accountName: String
    let nextOccurrence: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.small) {
            HStack(alignment: .firstTextBaseline) {
                Text(recurringTransaction.memo ?? "Recurring transaction")
                    .font(.body.weight(.medium))
                    .foregroundStyle(CairnColor.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: CairnSpacing.medium)

                Text(RecurringTransactionMoneyFormatter.currency(recurringTransaction.amount))
                    .cairnRowAmount()
                    .multilineTextAlignment(.trailing)
            }

            Text(recurringTransaction.direction.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(recurringTransaction.direction == .inflow ? CairnColor.positive : CairnColor.negative)

            Text(accountName)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text(recurringTransaction.frequency.displayName)
                .font(.footnote)
                .foregroundStyle(CairnColor.textSecondary)

            if let nextOccurrence {
                Text("Next \(RecurringTransactionDateFormatter.dateTime(nextOccurrence))")
                    .font(.footnote)
                    .foregroundStyle(CairnColor.textSecondary)
            } else {
                Text("No next occurrence")
                    .font(.footnote)
                    .foregroundStyle(CairnColor.textSecondary)
            }

            Text("Starts \(RecurringTransactionDateFormatter.dateTime(recurringTransaction.startDate))")
                .font(.footnote)
                .foregroundStyle(CairnColor.textTertiary)

            if let endDate = recurringTransaction.endDate {
                Text("Ends \(RecurringTransactionDateFormatter.dateTime(endDate))")
                    .font(.footnote)
                    .foregroundStyle(CairnColor.textTertiary)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
