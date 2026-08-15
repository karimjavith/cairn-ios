//
//  AccountEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct AccountEditorView: View {
    @Bindable var editor: AccountEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Account") {
                    TextField("Name", text: $editor.name)
                        .textContentType(.name)

                    Picker("Type", selection: $editor.type) {
                        ForEach(AccountType.allCases, id: \.self) { type in
                            Text(type.displayName)
                                .tag(type)
                        }
                    }
                }

                Section("Opening Balance") {
                    TextField("Amount", text: $editor.openingBalanceText)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)

                    TextField("Currency", text: $editor.currencyCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
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
                    .accessibilityLabel("Save Account")
                }
            }
        }
    }
}
