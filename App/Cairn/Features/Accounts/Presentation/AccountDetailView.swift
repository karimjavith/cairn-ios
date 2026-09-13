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
        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CairnSpacing.section) {
                    header

                    VStack(alignment: .leading, spacing: CairnSpacing.large) {
                        detailSection("Account") {
                            detailRow(title: "Name", value: account.name)
                            detailRow(title: "Type", value: account.type.displayName)
                            detailRow(title: "Currency", value: account.currencyCode)
                        }

                        detailSection("Balances") {
                            detailRow(
                                title: "Opening balance",
                                value: CairnMoneyPresentation.currency(account.openingBalance)
                            )
                            detailRow(title: "Current balance") {
                                currentBalanceView
                            }
                        }
                    }
                }
                .padding(.horizontal, CairnSpacing.extraLarge)
                .padding(.top, CairnSpacing.large)
                .padding(.bottom, CairnSpacing.section)
            }
        }
        .navigationTitle(account.name)
        .tint(CairnColor.plum)
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

    private var header: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            Text(account.type.displayName)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(CairnColor.plum)

            currentBalanceView
                .font(.system(.largeTitle, design: .serif).weight(.semibold))
                .monospacedDigit()
                .lineLimit(2)
                .minimumScaleFactor(0.76)
                .foregroundStyle(CairnColor.textPrimary)

            Text(account.currencyCode)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)
        }
        .accessibilityElement(children: .combine)
    }

    private func detailSection<Content: View>(
        _ title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            CairnSectionHeading(title)

            VStack(alignment: .leading, spacing: 0) {
                content()
            }
        }
    }

    private func detailRow(title: String, value: String) -> some View {
        detailRow(title: title) {
            Text(value)
                .foregroundStyle(CairnColor.textPrimary)
        }
    }

    private func detailRow<Content: View>(
        title: String,
        @ViewBuilder value: () -> Content
    ) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)

            Spacer(minLength: CairnSpacing.large)

            value()
                .font(.body.weight(.medium))
                .multilineTextAlignment(.trailing)
        }
        .padding(.vertical, CairnSpacing.small)
        .overlay(alignment: .bottom) {
            Divider()
                .overlay(CairnColor.separator)
        }
    }

    @ViewBuilder
    private var currentBalanceView: some View {
        switch balanceState {
        case let .loaded(balance):
            Text(CairnMoneyPresentation.currency(balance))
        case .loading:
            ProgressView()
                .tint(CairnColor.plum)
                .accessibilityLabel("Current balance loading")
        case .failed:
            Text("Unavailable")
                .foregroundStyle(CairnColor.textSecondary)
                .accessibilityLabel("Current balance unavailable")
        case nil:
            Text("Pending")
                .foregroundStyle(CairnColor.textSecondary)
        }
    }
}
