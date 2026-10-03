//
//  CairnEditorScaffold.swift
//  Cairn
//
//  Created by Codex on 26/09/2026.
//

import SwiftUI

struct CairnEditorScaffold<Content: View>: View {
    let title: String
    let saveAccessibilityLabel: String
    let isSaving: Bool
    let canSave: Bool
    let cancel: () -> Void
    let save: () -> Void
    private let content: Content

    init(
        title: String,
        saveAccessibilityLabel: String,
        isSaving: Bool,
        canSave: Bool,
        cancel: @escaping () -> Void,
        save: @escaping () -> Void,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.saveAccessibilityLabel = saveAccessibilityLabel
        self.isSaving = isSaving
        self.canSave = canSave
        self.cancel = cancel
        self.save = save
        self.content = content()
    }

    var body: some View {
        NavigationStack {
            Form {
                content
            }
            .contentMargins(.top, CairnSpacing.small, for: .scrollContent)
            .listSectionSpacing(CairnSpacing.medium)
            .scrollContentBackground(.hidden)
            .background(CairnColor.canvas)
            .navigationTitle(title)
            .tint(CairnColor.plum)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel)
                        .disabled(isSaving)
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button(action: save) {
                        if isSaving {
                            ProgressView()
                                .tint(CairnColor.plum)
                        } else {
                            Text("Save")
                        }
                    }
                    .disabled(!canSave || isSaving)
                    .accessibilityLabel(saveAccessibilityLabel)
                }
            }
            .interactiveDismissDisabled(isSaving)
        }
    }
}

struct CairnFormErrorView: View {
    let message: String

    var body: some View {
        Label {
            Text(message)
                .foregroundStyle(CairnColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)
        } icon: {
            Image(systemName: "exclamationmark.triangle")
                .foregroundStyle(CairnColor.warning)
                .accessibilityHidden(true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(message)
    }
}

struct CairnEditorSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .foregroundStyle(CairnColor.textSecondary)
    }
}

struct CairnEditorSupportingText: View {
    let text: String

    var body: some View {
        Text(text)
            .foregroundStyle(CairnColor.textSecondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
