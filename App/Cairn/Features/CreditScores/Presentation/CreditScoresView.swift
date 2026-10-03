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
    private enum Field: Hashable {
        case value
    }

    @Bindable var editor: CreditScoreEditorState
    let cancel: () -> Void
    let save: () -> Void
    @FocusState private var focusedField: Field?

    var body: some View {
        CairnEditorScaffold(
            title: editor.isEditing ? "Update Credit Score" : "Add Credit Score",
            saveAccessibilityLabel: "Save credit score",
            isSaving: editor.isSaving,
            canSave: editor.canSave,
            cancel: cancel,
            save: save
        ) {
            Section {
                LabeledContent("Provider", value: editor.provider.displayName)

                VStack(alignment: .leading, spacing: CairnSpacing.small) {
                    Text("Score")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(CairnColor.textPrimary)

                    TextField("Enter score", text: $editor.valueText)
                        .keyboardType(.numberPad)
                        .textInputAutocapitalization(.never)
                        .focused($focusedField, equals: .value)
                        .monospacedDigit()
                        .accessibilityLabel("Credit score")
                        .accessibilityHint(scoreAccessibilityHint)
                }

                if availableScales.count > 1 {
                    Picker("Score scale", selection: $editor.scale) {
                        Text("Select score scale").tag(CreditScoreScale?.none)
                        ForEach(availableScales, id: \.self) { scale in
                            Text(scaleLabel(scale)).tag(Optional(scale))
                        }
                    }
                    .accessibilityHint("Select the score range shown by your provider.")
                } else if let scale = editor.scale {
                    LabeledContent("Score scale", value: scaleLabel(scale))
                }
            } header: {
                CairnEditorSectionHeader(title: "Score details")
            } footer: {
                CairnEditorSupportingText(text: supportingText)
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
            if !editor.isEditing {
                focusedField = .value
            }
        }
    }

    private var availableScales: [CreditScoreScale] {
        CreditScoreScale.available(for: editor.provider)
    }

    private var supportingText: String {
        if let scale = editor.scale {
            "Enter a whole number from 0 to \(scale.maximum). This score is entered manually and stays on this device."
        } else {
            "Select the score scale shown by your provider. This score is entered manually and stays on this device."
        }
    }

    private var scoreAccessibilityHint: String {
        if let scale = editor.scale {
            "Enter a whole number from 0 to \(scale.maximum)."
        } else {
            "Select a score scale, then enter the whole-number score."
        }
    }

    private func scaleLabel(_ scale: CreditScoreScale) -> String {
        "0–\(scale.maximum)"
    }
}
