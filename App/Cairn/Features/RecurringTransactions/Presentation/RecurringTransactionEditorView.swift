//
//  RecurringTransactionEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct RecurringTransactionEditorView: View {
    private enum Field: Hashable {
        case amount
        case memo
    }

    @Bindable var editor: RecurringTransactionEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    var body: some View {
        CairnEditorScaffold(
            title: editor.title,
            saveAccessibilityLabel: "Save Recurring Transaction",
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
                        .accessibilityLabel("Recurring transaction amount")
                        .accessibilityHint("Enter the amount for each recurring transaction.")
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
                .accessibilityHint("Select the account used by this recurring transaction.")
            } header: {
                CairnEditorSectionHeader(title: "Transaction details")
            }

            Section {
                Picker("Frequency", selection: $editor.frequency) {
                    ForEach(RecurrenceFrequency.allCases, id: \.self) { frequency in
                        Text(frequency.displayName)
                            .tag(frequency)
                    }
                }

                DatePicker(
                    "Start",
                    selection: $editor.startDate,
                    displayedComponents: [.date, .hourAndMinute]
                )

                Toggle("Use end date", isOn: $editor.hasEndDate)

                if editor.hasEndDate {
                    DatePicker(
                        "End",
                        selection: $editor.endDate,
                        displayedComponents: [.date, .hourAndMinute]
                    )
                }
            } header: {
                CairnEditorSectionHeader(title: "Schedule")
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
                        .accessibilityHint("Add an optional note for this recurring transaction.")
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
