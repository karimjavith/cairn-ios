//
//  CategoryEditorView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct CategoryEditorView: View {
    @Bindable var editor: CategoryEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section("Category") {
                    TextField("Name", text: $editor.name)
                        .textContentType(.name)

                    Picker("Kind", selection: $editor.kind) {
                        ForEach(CategoryKind.allCases, id: \.self) { kind in
                            Text(kind.displayName)
                                .tag(kind)
                        }
                    }
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
                    .accessibilityLabel("Save Category")
                }
            }
        }
    }
}
