//
//  AccountsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct AccountsView: View {
    @State private var store: AccountsStore
    @State private var handledCreateAccountRequest: UUID?
    let createAccountRequest: UUID?

    init(
        accountRepository: any AccountRepository,
        transactionRepository: any TransactionRepository,
        calculateAccountBalance: CalculateAccountBalance,
        createAccountRequest: UUID? = nil
    ) {
        self.createAccountRequest = createAccountRequest
        _store = State(wrappedValue: AccountsStore(
            accountRepository: accountRepository,
            transactionRepository: transactionRepository,
            calculateAccountBalance: calculateAccountBalance
        ))
    }

    var body: some View {
        @Bindable var store = store

        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            if store.isLoading {
                ProgressView("Loading accounts")
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                VStack {
                    LoadFailureView(
                        title: "Accounts Unavailable",
                        message: errorMessage,
                        retry: {
                            Task {
                                await store.loadAccounts()
                            }
                        }
                    )
                }
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else if store.isEmpty {
                emptyAccountsView
            } else {
                accountsContent
            }
        }
        .navigationTitle("Accounts")
        .tint(CairnColor.plum)
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
        .onAppear {
            handleCreateAccountRequest(createAccountRequest)
        }
        .onChange(of: createAccountRequest) { _, request in
            handleCreateAccountRequest(request)
        }
    }

    private func handleCreateAccountRequest(_ request: UUID?) {
        guard let request, handledCreateAccountRequest != request else {
            return
        }

        handledCreateAccountRequest = request
        store.startCreateAccount()
    }

    private var emptyAccountsView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "Your accounts, in one place.",
                message: "Add your first account to start tracking balances and activity.",
                systemImage: "creditcard",
                actionLabel: "Add account",
                action: { store.startCreateAccount() }
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
        .scrollContentBackground(.hidden)
    }

    private var accountsContent: some View {
        List {
            accountSummary
                .listRowInsets(EdgeInsets(
                    top: CairnSpacing.large,
                    leading: CairnSpacing.extraLarge,
                    bottom: CairnSpacing.section,
                    trailing: CairnSpacing.extraLarge
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(CairnColor.canvas)

            ForEach(store.accounts, id: \.id) { account in
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
                .contextMenu {
                    Button(role: .destructive) {
                        store.requestDelete(account)
                    } label: {
                        Label("Delete \(account.name)", systemImage: "trash")
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

                if account.id != store.accounts.last?.id {
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

    @ViewBuilder
    private var accountSummary: some View {
        if let summaries = AccountListPresentation.currencySummaries(
            accounts: store.accounts,
            balances: loadedBalances
        ) {
            if summaries.count == 1, let summary = summaries.first {
                VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                    Text("Total balance")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(CairnColor.plum)

                    Text(CairnMoneyPresentation.currency(summary.total))
                        .font(.system(.largeTitle, design: .serif).weight(.semibold))
                        .monospacedDigit()
                        .lineLimit(2)
                        .minimumScaleFactor(0.76)
                        .foregroundStyle(CairnColor.textPrimary)

                    Text(AccountListPresentation.accountCountText(
                        summary.accountCount,
                        currencyCode: summary.currencyCode
                    ))
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    "Total balance, \(CairnMoneyPresentation.currency(summary.total)), \(AccountListPresentation.accountCountText(summary.accountCount, currencyCode: summary.currencyCode))"
                )
            } else {
                VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                    Text("Balances")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(CairnColor.textPrimary)

                    VStack(alignment: .leading, spacing: CairnSpacing.small) {
                        ForEach(summaries, id: \.currencyCode) { summary in
                            HStack(alignment: .firstTextBaseline) {
                                Text(summary.currencyCode)
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(CairnColor.textSecondary)

                                Spacer(minLength: CairnSpacing.large)

                                Text(CairnMoneyPresentation.currency(summary.total))
                                    .cairnRowAmount()
                                    .foregroundStyle(CairnColor.textPrimary)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }

                    Text("Cairn does not convert currencies.")
                        .font(.subheadline)
                        .foregroundStyle(CairnColor.textSecondary)
                }
            }
        } else {
            VStack(alignment: .leading, spacing: CairnSpacing.small) {
                Text("Balances")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(CairnColor.textPrimary)

                Text("Current balances are updating.")
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textSecondary)
            }
        }
    }

    private var loadedBalances: [AccountID: Money] {
        store.balances.compactMapValues { state in
            if case let .loaded(balance) = state {
                return balance
            }

            return nil
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
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            CairnFinancialRow(
                title: account.name,
                metadata: account.type.displayName,
                trailing: balanceText,
                accessibilityLabel: ""
            )
            .accessibilityHidden(true)

            Image(systemName: "chevron.right")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(CairnColor.textTertiary)
                .accessibilityHidden(true)
        }
        .padding(.vertical, CairnSpacing.extraSmall)
        .contentShape(Rectangle())
    }

    private var balanceText: String {
        switch balanceState {
        case let .loaded(balance):
            CairnMoneyPresentation.currency(balance)
        case .loading:
            "Loading"
        case .failed:
            "Unavailable"
        case nil:
            "Pending"
        }
    }
}
