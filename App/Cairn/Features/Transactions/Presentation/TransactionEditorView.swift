//
//  TransactionEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct TransactionEditorView: View {
    @Bindable var editor: TransactionEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Transaction") {
                    Picker("Account", selection: $editor.selectedAccountID) {
                        if editor.accounts.isEmpty {
                            Text("No Accounts").tag(AccountID?.none)
                        }

                        ForEach(editor.accounts, id: \.id) { account in
                            Text(account.name)
                                .tag(Optional(account.id))
                        }
                    }

                    Picker("Direction", selection: $editor.direction) {
                        ForEach(TransactionDirection.allCases, id: \.self) { direction in
                            Text(direction.displayName)
                                .tag(direction)
                        }
                    }

                    TextField("Amount", text: $editor.amountText)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)

                    DatePicker("Date", selection: $editor.occurredAt)
                }

                Section("Category") {
                    Picker("Category", selection: $editor.selectedCategoryID) {
                        Text("Uncategorized")
                            .tag(CategoryID?.none)

                        ForEach(editor.categories, id: \.id) { category in
                            Text(category.name)
                                .tag(Optional(category.id))
                        }
                    }
                }

                Section("Memo") {
                    TextField("Memo", text: $editor.memo, axis: .vertical)
                        .lineLimit(1...4)
                }

                if let errorMessage = editor.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(.secondary)
                            .accessibilityLabel(errorMessage)
                    }
                }
            }
            .navigationTitle(editor.title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                        .disabled(editor.isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        save()
                    } label: {
                        if editor.isSaving {
                            ProgressView()
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(editor.isSaving)
                    .accessibilityLabel("Save Transaction")
                }
            }
        }
    }
}
