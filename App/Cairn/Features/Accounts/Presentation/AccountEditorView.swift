//
//  AccountEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct AccountEditorView: View {
    private enum Field: Hashable {
        case name
        case openingBalance
    }

    @Bindable var editor: AccountEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    private let currencyCodes = Locale.Currency.isoCurrencies
        .map(\.identifier)
        .sorted()

    var body: some View {
        CairnEditorScaffold(
            title: editor.title,
            saveAccessibilityLabel: "Save Account",
            isSaving: editor.isSaving,
            canSave: editor.canSave,
            cancel: cancel,
            save: save
        ) {
            Section {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Account name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("For example, Everyday account", text: $editor.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .openingBalance
                        }
                        .accessibilityLabel("Account name")
                        .accessibilityHint("Enter a name that helps you identify this account.")
                }

                Picker("Account type", selection: $editor.type) {
                    ForEach(AccountType.allCases, id: \.self) { type in
                        Text(type.displayName)
                            .tag(type)
                    }
                }
                .accessibilityHint("Select the kind of financial account.")
            } header: {
                CairnEditorSectionHeader(title: "Account details")
            }

            Section {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Amount")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("0.00", text: $editor.openingBalanceText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .openingBalance)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .monospacedDigit()
                        .accessibilityLabel("Opening balance amount")
                        .accessibilityHint("Enter the account balance before any transactions in Cairn.")
                }

                Picker("Currency", selection: $editor.currencyCode) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text(currencyLabel(for: currencyCode))
                            .tag(currencyCode)
                    }
                }
                .accessibilityHint("Select the currency used by this account.")
            } header: {
                CairnEditorSectionHeader(title: "Opening balance")
            } footer: {
                CairnEditorSupportingText(
                    text: "Enter the balance before adding transactions. Use a negative amount when the account starts in debt."
                )
            }

            if let errorMessage = editor.errorMessage {
                Section {
                    CairnFormErrorView(message: errorMessage)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    focusedField = nil
                }
            }
        }
        .task {
            if editor.mode == .create {
                focusedField = .name
            }
        }
    }

    private func currencyLabel(for currencyCode: String) -> String {
        guard let currencyName = Locale.current.localizedString(forCurrencyCode: currencyCode) else {
            return currencyCode
        }

        return "\(currencyCode) — \(currencyName)"
    }
}
