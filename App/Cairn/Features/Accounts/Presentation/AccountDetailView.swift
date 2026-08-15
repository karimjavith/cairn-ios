//
//  AccountDetailView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct AccountDetailView: View {
    let account: Account
    let balanceState: AccountsStore.BalanceState?
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        Form {
            Section("Account") {
                LabeledContent("Name", value: account.name)
                LabeledContent("Type", value: account.type.displayName)
                LabeledContent("Currency", value: account.currencyCode)
            }

            Section("Balances") {
                LabeledContent(
                    "Opening Balance",
                    value: AccountMoneyFormatter.currency(account.openingBalance)
                )
                LabeledContent("Current Balance") {
                    currentBalanceView
                }
            }
        }
        .navigationTitle(account.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
                    .accessibilityLabel("Edit \(account.name)")
            }

            ToolbarItem(placement: .bottomBar) {
                Button(role: .destructive, action: delete) {
                    Label("Delete Account", systemImage: "trash")
                }
                .accessibilityLabel("Delete \(account.name)")
            }
        }
    }

    @ViewBuilder
    private var currentBalanceView: some View {
        switch balanceState {
        case let .loaded(balance):
            Text(AccountMoneyFormatter.currency(balance))
        case .loading:
            ProgressView()
                .accessibilityLabel("Current balance loading")
        case .failed:
            Text("Unavailable")
                .foregroundStyle(.secondary)
                .accessibilityLabel("Current balance unavailable")
        case nil:
            Text("Pending")
                .foregroundStyle(.secondary)
        }
    }
}
