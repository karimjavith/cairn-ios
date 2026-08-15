//
//  RecurringTransactionEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct RecurringTransactionEditorView: View {
    @Bindable var editor: RecurringTransactionEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Recurring Transaction") {
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

                    Picker("Frequency", selection: $editor.frequency) {
                        ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                            Text(frequency.displayName)
                                .tag(frequency)
                        }
                    }
                }

                Section("Schedule") {
                    DatePicker("Start Date", selection: $editor.startDate)

                    Toggle("End Date", isOn: $editor.hasEndDate)

                    if editor.hasEndDate {
                        DatePicker("End Date", selection: $editor.endDate)
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
                    .accessibilityLabel("Save Recurring Transaction")
                }
            }
        }
    }
}
