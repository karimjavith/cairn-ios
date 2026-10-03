//
//  GoalEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct GoalEditorView: View {
    private enum Field: Hashable {
        case name
        case targetAmount
        case currentAmount
    }

    @Bindable var editor: GoalEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    private let currencyCodes = Locale.Currency.isoCurrencies
        .map(\.identifier)
        .sorted()

    var body: some View {
        CairnEditorScaffold(
            title: editor.title,
            saveAccessibilityLabel: "Save Goal",
            isSaving: editor.isSaving,
            canSave: editor.canSave,
            cancel: cancel,
            save: save
        ) {
            Section {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Goal name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("For example, Emergency fund", text: $editor.name)
                        .textInputAutocapitalization(.words)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .targetAmount
                        }
                        .accessibilityLabel("Goal name")
                        .accessibilityHint("Enter a name that helps you identify this goal.")
                }

                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Target amount")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("0.00", text: $editor.targetAmountText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .targetAmount)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .currentAmount
                        }
                        .monospacedDigit()
                        .accessibilityLabel("Target amount")
                        .accessibilityHint("Enter the total amount for this goal.")
                }

                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Saved amount")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("0.00", text: $editor.currentAmountText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .currentAmount)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .monospacedDigit()
                        .accessibilityLabel("Saved amount")
                        .accessibilityHint("Enter the amount already saved toward this goal.")
                }

                Picker("Currency", selection: $editor.currencyCode) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text(currencyLabel(for: currencyCode))
                            .tag(currencyCode)
                    }
                }
            } header: {
                CairnEditorSectionHeader(title: "Goal details")
            }

            Section {
                Toggle("Use target date", isOn: $editor.hasTargetDate)

                if editor.hasTargetDate {
                    DatePicker("Target date", selection: $editor.targetDate, displayedComponents: .date)
                }
            } header: {
                CairnEditorSectionHeader(title: "Target date")
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
