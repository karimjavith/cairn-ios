import Foundation
import Observation

@MainActor
@Observable
final class CreditScoresStore {
    private let repository: any CreditScoreRepository
    private let now: @MainActor () -> Date

    private(set) var scores: [CreditScore] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var editor: CreditScoreEditorState?

    init(repository: any CreditScoreRepository, now: @escaping @MainActor () -> Date = { Date() }) {
        self.repository = repository
        self.now = now
    }

    func load() async {
        isLoading = true
        errorMessage = nil
        do {
            scores = try await repository.fetchScores()
        } catch {
            errorMessage = "Credit scores could not be loaded."
        }
        isLoading = false
    }

    func score(for provider: CreditScoreProvider) -> CreditScore? {
        scores.first { $0.provider == provider }
    }

    func edit(_ provider: CreditScoreProvider) {
        editor = CreditScoreEditorState(provider: provider, existing: score(for: provider))
    }

    func dismissEditor() {
        editor = nil
    }

    func saveEditor() async {
        guard let editor else { return }
        editor.isSaving = true
        editor.errorMessage = nil

        do {
            let score = try editor.makeScore(updatedAt: now())
            try await repository.save(score)
            self.editor = nil
            await load()
        } catch CreditScoreEditorState.EntryError.missingScale {
            editor.errorMessage = "Select a score scale."
            editor.isSaving = false
        } catch CreditScoreEditorState.EntryError.invalidNumber {
            editor.errorMessage = "Enter a whole-number credit score."
            editor.isSaving = false
        } catch CreditScore.ValidationError.outOfRange {
            editor.errorMessage = editor.scale.map { "Enter a score from 0 to \($0.maximum)." }
                ?? "Select a score scale."
            editor.isSaving = false
        } catch {
            editor.errorMessage = "Credit score could not be saved."
            editor.isSaving = false
        }
    }
}

@MainActor
@Observable
final class CreditScoreEditorState: Identifiable {
    enum EntryError: Error, Equatable { case missingScale, invalidNumber }

    let id: CreditScoreProvider
    let provider: CreditScoreProvider
    let isEditing: Bool
    var scale: CreditScoreScale?
    var valueText: String
    var isSaving = false
    var errorMessage: String?

    init(provider: CreditScoreProvider, existing: CreditScore?) {
        self.id = provider
        self.provider = provider
        isEditing = existing != nil
        let availableScales = CreditScoreScale.available(for: provider)
        scale = existing?.scale ?? (availableScales.count == 1 ? availableScales.first : nil)
        valueText = existing.map { String($0.value) } ?? ""
    }

    var canSave: Bool {
        !isSaving && (try? makeScore(updatedAt: .distantPast)) != nil
    }

    func makeScore(updatedAt: Date) throws -> CreditScore {
        guard let scale else { throw EntryError.missingScale }
        guard let value = parsedValue else { throw EntryError.invalidNumber }
        return try CreditScore(provider: provider, scale: scale, value: value, updatedAt: updatedAt)
    }

    private var parsedValue: Int? {
        let text = valueText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty,
              text.allSatisfy(\.isNumber),
              let value = Int(text) else {
            return nil
        }
        return value
    }
}
