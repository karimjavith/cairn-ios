import SwiftUI

struct CreditScoresView: View {
    @State private var store: CreditScoresStore

    init(repository: any CreditScoreRepository) {
        _store = State(wrappedValue: CreditScoresStore(repository: repository))
    }

    var body: some View {
        @Bindable var store = store

        ZStack {
            CairnColor.canvas.ignoresSafeArea()

            if store.isLoading && store.scores.isEmpty {
                ProgressView("Loading credit scores")
                    .tint(CairnColor.plum)
            } else if let errorMessage = store.errorMessage, store.scores.isEmpty {
                LoadFailureView(
                    title: "Credit Scores Unavailable",
                    message: errorMessage,
                    retry: { Task { await store.load() } }
                )
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else {
                scoreList
            }
        }
        .navigationTitle("Credit Score")
        .tint(CairnColor.plum)
        .sheet(item: $store.editor) { editor in
            CreditScoreEditorView(
                editor: editor,
                cancel: { store.dismissEditor() },
                save: { Task { await store.saveEditor() } }
            )
        }
        .safeAreaInset(edge: .bottom) {
            if let errorMessage = store.errorMessage, !store.scores.isEmpty {
                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(CairnColor.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(CairnSpacing.large)
                    .background(CairnColor.lavenderSurface)
                    .accessibilityLabel(errorMessage)
            }
        }
        .task { await store.load() }
    }

    private var scoreList: some View {
        List {
            CairnSectionHeading(
                "Your credit scores",
                subtitle: "Enter the score shown by each provider. Scores use different scales."
            )
            .listRowInsets(EdgeInsets(
                top: CairnSpacing.large,
                leading: CairnSpacing.extraLarge,
                bottom: CairnSpacing.medium,
                trailing: CairnSpacing.extraLarge
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(CairnColor.canvas)

            ForEach(CreditScoreProvider.allCases, id: \.self) { provider in
                Button {
                    store.edit(provider)
                } label: {
                    scoreRow(provider)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(rowAccessibilityLabel(provider))
                .listRowInsets(EdgeInsets(
                    top: CairnSpacing.small,
                    leading: CairnSpacing.extraLarge,
                    bottom: CairnSpacing.small,
                    trailing: CairnSpacing.extraLarge
                ))
                .listRowBackground(CairnColor.canvas)
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func scoreRow(_ provider: CreditScoreProvider) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
                Text(provider.displayName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CairnColor.textPrimary)

                if let score = store.score(for: provider) {
                    Text("Manually entered · Updated \(score.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                        .font(.footnote)
                        .foregroundStyle(CairnColor.textSecondary)
                } else {
                    Text("Add score")
                        .font(.subheadline)
                        .foregroundStyle(CairnColor.textSecondary)
                }
            }

            Spacer(minLength: CairnSpacing.medium)

            if let score = store.score(for: provider) {
                VStack(alignment: .trailing, spacing: CairnSpacing.extraSmall) {
                    Text(score.value.formatted())
                        .cairnRowAmount()
                        .foregroundStyle(CairnColor.textPrimary)
                    Text("of \(score.scale.maximum.formatted())")
                        .font(.caption)
                        .foregroundStyle(CairnColor.textSecondary)
                }
            } else {
                Image(systemName: "plus")
                    .foregroundStyle(CairnColor.plum)
                    .accessibilityHidden(true)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }

    private func rowAccessibilityLabel(_ provider: CreditScoreProvider) -> String {
        guard let score = store.score(for: provider) else {
            return "\(provider.displayName), add score"
        }
        return "\(provider.displayName), \(score.value) of \(score.scale.maximum), manually entered, updated \(score.updatedAt.formatted(date: .abbreviated, time: .omitted)), edit score"
    }
}

private struct CreditScoreEditorView: View {
    @Bindable var editor: CreditScoreEditorState
    let cancel: () -> Void
    let save: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Credit Score", text: $editor.valueText)
                        .keyboardType(.numberPad)
                        .monospacedDigit()

                    if CreditScoreScale.available(for: editor.provider).count > 1 {
                        Picker("Score scale", selection: $editor.scale) {
                            Text("Select score scale").tag(CreditScoreScale?.none)
                            ForEach(CreditScoreScale.available(for: editor.provider), id: \.self) { scale in
                                Text("0–\(scale.maximum)").tag(Optional(scale))
                            }
                        }
                    }
                } header: {
                    Text(editor.provider.displayName)
                } footer: {
                    if let scale = editor.scale {
                        Text("Enter a whole number from 0 to \(scale.maximum). This score is entered manually and stays on this device.")
                    } else {
                        Text("Select the score scale shown by your provider. This score is entered manually and stays on this device.")
                    }
                }

                if let errorMessage = editor.errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundStyle(CairnColor.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityLabel(errorMessage)
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(CairnColor.canvas)
            .navigationTitle(editor.isEditing ? "Update Credit Score" : "Add Credit Score")
            .tint(CairnColor.plum)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", action: cancel).disabled(editor.isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!editor.canSave)
                        .accessibilityLabel("Save credit score")
                }
            }
        }
    }
}
