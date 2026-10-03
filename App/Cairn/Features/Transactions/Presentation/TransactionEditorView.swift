//
//  TransactionEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct TransactionEditorView: View {
    private enum Field: Hashable {
        case amount
        case memo
    }

    @Bindable var editor: TransactionEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    var body: some View {
        CairnEditorScaffold(
            title: editor.title,
            saveAccessibilityLabel: "Save Transaction",
            isSaving: editor.isSaving,
            canSave: editor.canSave,
            cancel: cancel,
            save: save
        ) {
            Section {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Transaction type")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    Picker("Transaction type", selection: $editor.direction) {
                        ForEach(TransactionDirection.allCases, id: \.self) { direction in
                            Text(direction.displayName)
                                .tag(direction)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }

                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Amount")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("0.00", text: $editor.amountText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .amount)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .memo
                        }
                        .monospacedDigit()
                        .accessibilityLabel("Transaction amount")
                        .accessibilityHint("Enter the amount of the transaction.")
                }

                Picker("Account", selection: $editor.selectedAccountID) {
                    if editor.accounts.isEmpty {
                        Text("No accounts").tag(AccountID?.none)
                    }

                    ForEach(editor.accounts, id: \.id) { account in
                        Text(account.name)
                            .tag(Optional(account.id))
                    }
                }

                DatePicker(
                    "Date and time",
                    selection: $editor.occurredAt,
                    displayedComponents: [.date, .hourAndMinute]
                )
            } header: {
                CairnEditorSectionHeader(title: "Transaction details")
            }

            Section {
                Picker("Category", selection: $editor.selectedCategoryID) {
                    Text("Uncategorized")
                        .tag(CategoryID?.none)

                    ForEach(editor.categories, id: \.id) { category in
                        Text(category.name)
                            .tag(Optional(category.id))
                    }
                }
            } header: {
                CairnEditorSectionHeader(title: "Category")
            }

            Section {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Memo")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("Optional", text: $editor.memo, axis: .vertical)
                        .lineLimit(1...4)
                        .focused($focusedField, equals: .memo)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                }
            } header: {
                CairnEditorSectionHeader(title: "Note")
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
                focusedField = .amount
            }
        }
    }
}
