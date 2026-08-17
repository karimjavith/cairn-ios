//
//  AccountsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct AccountsView: View {
    @State private var store: AccountsStore

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository,
        calculateAccountBalance: CalculateAccountBalance
    ) {
        _store = State(wrappedValue: AccountsStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository,
            calculateAccountBalance: calculateAccountBalance
        ))
    }

    var body: some View {
        @Bindable var store = store

        Group {
            if store.isLoading {
                ProgressView("Loading accounts")
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Accounts Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadAccounts()
                        }
                    }
                )
            } else if store.isEmpty {
                ContentUnavailableView(
                    "No Accounts",
                    systemImage: "creditcard",
                    description: Text("Add your first account to start tracking balances.")
                )
            } else {
                accountList
            }
        }
        .navigationTitle("Accounts")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startCreateAccount()
                } label: {
                    Label("Add Account", systemImage: "plus")
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
            AccountEditorView(
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
            "Delete Account?",
            isPresented: Binding(
                get: { store.pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelDelete()
                    }
                }
            ),
            presenting: store.pendingDeletion
        ) { account in
            Button("Delete \(account.name)", role: .destructive) {
                Task {
                    await store.confirmDelete(account)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { account in
            Text("This deletes \(account.name) using the current account repository behavior.")
        }
        .navigationDestination(item: $store.route) { route in
            switch route {
            case let .detail(accountID):
                if let account = store.account(id: accountID) {
                    AccountDetailView(
                        account: account,
                        balanceState: store.balances[accountID],
                        edit: { store.startEditing(account) },
                        delete: { store.requestDelete(account) }
                    )
                } else {
                    ContentUnavailableView(
                        "Account Not Found",
                        systemImage: "questionmark.folder",
                        description: Text("The selected account is no longer available.")
                    )
                }
            }
        }
        .task {
            await store.loadAccounts()
        }
    }

    private var accountList: some View {
        List(store.accounts, id: \.id) { account in
            Button {
                store.selectDetail(accountID: account.id)
            } label: {
                AccountRowView(
                    account: account,
                    balanceState: store.balances[account.id]
                )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(accessibilityLabel(for: account))
            .swipeActions {
                Button(role: .destructive) {
                    store.requestDelete(account)
                } label: {
                    Label("Delete \(account.name)", systemImage: "trash")
                }
                .accessibilityLabel("Delete \(account.name)")
            }
        }
    }

    private func accessibilityLabel(for account: Account) -> String {
        let balanceText: String

        switch store.balances[account.id] {
        case let .loaded(balance):
            balanceText = AccountMoneyFormatter.currency(balance)
        case .loading:
            balanceText = "balance loading"
        case .failed:
            balanceText = "balance unavailable"
        case nil:
            balanceText = "balance pending"
        }

        return "\(account.name), \(account.type.displayName), current balance \(balanceText)"
    }
}

private struct AccountRowView: View {
    let account: Account
    let balanceState: AccountsStore.BalanceState?

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            VStack(alignment: .leading, spacing: 4) {
                Text(account.name)
                    .font(.body)
                Text(account.type.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 16)

            balanceView
                .font(.body.monospacedDigit())
                .multilineTextAlignment(.trailing)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var balanceView: some View {
        switch balanceState {
        case let .loaded(balance):
            Text(AccountMoneyFormatter.currency(balance))
        case .loading:
            ProgressView()
                .accessibilityLabel("Current balance loading")
        case .failed:
            Label("Balance unavailable", systemImage: "exclamationmark.triangle")
                .labelStyle(.iconOnly)
                .foregroundStyle(.secondary)
                .accessibilityLabel("Current balance unavailable")
        case nil:
            Text("Pending")
                .foregroundStyle(.secondary)
        }
    }
}
