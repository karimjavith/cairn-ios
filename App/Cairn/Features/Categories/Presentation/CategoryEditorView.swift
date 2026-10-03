//
//  CategoryEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct CategoryEditorView: View {
    private enum Field: Hashable {
        case name
    }

    @Bindable var editor: CategoryEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    var body: some View {
        CairnEditorScaffold(
            title: editor.title,
            saveAccessibilityLabel: "Save Category",
            isSaving: editor.isSaving,
            canSave: editor.canSave,
            cancel: cancel,
            save: save
        ) {
            Section {
                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Category name")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("For example, Groceries", text: $editor.name)
                        .textInputAutocapitalization(.words)
                        .autocorrectionDisabled(false)
                        .focused($focusedField, equals: .name)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                        .accessibilityLabel("Category name")
                        .accessibilityHint("Enter a name that helps you identify this category.")
                }

                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Category type")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    Picker("Category type", selection: $editor.kind) {
                        ForEach(CategoryKind.allCases, id: \.self) { kind in
                            Text(kind.displayName)
                                .tag(kind)
                        }
                    }
                    .pickerStyle(.segmented)
                    .labelsHidden()
                }
            } header: {
                CairnEditorSectionHeader(title: "Category details")
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
}
