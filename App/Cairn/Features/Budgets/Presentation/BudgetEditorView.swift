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
                        .monospacedDigit()

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
                        Label {
                            Text(errorMessage)
                                .foregroundStyle(CairnColor.textSecondary)
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
                    .accessibilityLabel("Save Budget")
                }
            }
        }
    }
}
