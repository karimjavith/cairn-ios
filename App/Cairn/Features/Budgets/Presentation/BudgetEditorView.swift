//
//  BudgetEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct BudgetEditorView: View {
    private enum Field: Hashable {
        case limit
    }

    @Bindable var editor: BudgetEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    private let currencyCodes = Locale.Currency.isoCurrencies
        .map(\.identifier)
        .sorted()

    var body: some View {
        CairnEditorScaffold(
            title: editor.title,
            saveAccessibilityLabel: "Save Budget",
            isSaving: editor.isSaving,
            canSave: editor.canSave,
            cancel: cancel,
            save: save
        ) {
            Section {
                Picker("Category", selection: $editor.selectedCategoryID) {
                    if editor.categories.isEmpty {
                        Text("No categories").tag(CategoryID?.none)
                    }

                    ForEach(editor.categories, id: \.id) { category in
                        Text(category.name)
                            .tag(Optional(category.id))
                    }
                }

                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Limit")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("0.00", text: $editor.limitText)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .limit)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .monospacedDigit()
                        .accessibilityLabel("Budget limit")
                        .accessibilityHint("Enter the maximum amount for this budget.")
                }

                Picker("Currency", selection: $editor.currencyCode) {
                    ForEach(currencyCodes, id: \.self) { currencyCode in
                        Text(currencyLabel(for: currencyCode))
                            .tag(currencyCode)
                    }
                }
            } header: {
                CairnEditorSectionHeader(title: "Budget details")
            }

            Section {
                DatePicker("Start", selection: $editor.startDate)
                DatePicker("End", selection: $editor.endDate)
            } header: {
                CairnEditorSectionHeader(title: "Period")
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
                focusedField = .limit
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
