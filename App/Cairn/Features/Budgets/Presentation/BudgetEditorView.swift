//
//  BudgetEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct BudgetEditorView: View {
    @Bindable var editor: BudgetEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Budget") {
                    Picker("Category", selection: $editor.selectedCategoryID) {
                        if editor.categories.isEmpty {
                            Text("No Categories").tag(CategoryID?.none)
                        }

                        ForEach(editor.categories, id: \.id) { category in
                            Text(category.name)
                                .tag(Optional(category.id))
                        }
                    }

                    TextField("Limit", text: $editor.limitText)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)

                    TextField("Currency", text: $editor.currencyCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Period") {
                    DatePicker("Start", selection: $editor.startDate)
                    DatePicker("End", selection: $editor.endDate)
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
                    .accessibilityLabel("Save Budget")
                }
            }
        }
    }
}
