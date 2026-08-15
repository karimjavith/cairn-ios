//
//  GoalEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct GoalEditorView: View {
    @Bindable var editor: GoalEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Goal") {
                    TextField("Name", text: $editor.name)
                        .textInputAutocapitalization(.words)

                    TextField("Target Amount", text: $editor.targetAmountText)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)

                    TextField("Current Amount", text: $editor.currentAmountText)
                        .keyboardType(.decimalPad)
                        .textInputAutocapitalization(.never)

                    TextField("Currency", text: $editor.currencyCode)
                        .textInputAutocapitalization(.characters)
                        .autocorrectionDisabled()
                }

                Section("Target Date") {
                    Toggle("Use Target Date", isOn: $editor.hasTargetDate)

                    if editor.hasTargetDate {
                        DatePicker("Target Date", selection: $editor.targetDate, displayedComponents: .date)
                    }
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
                    .accessibilityLabel("Save Goal")
                }
            }
        }
    }
}
