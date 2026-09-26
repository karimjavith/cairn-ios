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
                        .monospacedDigit()

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
                        Label {
                            Text(errorMessage)
                                .foregroundStyle(CairnColor.textSecondary)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle")
                                .foregroundStyle(CairnColor.warning)
                                .accessibilityHidden(true)
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(errorMessage)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CairnColor.canvas)
            .navigationTitle(editor.title)
            .tint(CairnColor.plum)
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
                                .tint(CairnColor.plum)
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
