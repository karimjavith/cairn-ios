import Foundation
import Testing
@testable import Cairn

@MainActor
struct CreditScoresStoreTests {
    @Test func newMultiScaleProviderRequiresExplicitScaleAndValidValue() throws {
        for provider in [CreditScoreProvider.experian, .transUnion] {
            let editor = CreditScoreEditorState(provider: provider, existing: nil)
            #expect(editor.scale == nil)
            editor.valueText = "700"
            #expect(!editor.canSave)
            #expect(throws: CreditScoreEditorState.EntryError.missingScale) {
                try editor.makeScore(updatedAt: Date())
            }
        }

        let editor = CreditScoreEditorState(provider: .transUnion, existing: nil)
        editor.scale = .transUnion710
        editor.valueText = "711"
        #expect(!editor.canSave)
        editor.valueText = "710"
        #expect(editor.canSave)
        editor.scale = .transUnion999
        editor.valueText = "999"
        #expect(editor.canSave)
        editor.valueText = "1000"
        #expect(!editor.canSave)
    }

    @Test func singleScaleProviderSelectsItsOnlyScale() {
        let editor = CreditScoreEditorState(provider: .equifax, existing: nil)
        #expect(editor.scale == .equifax1000)
        #expect(!editor.canSave)
        editor.valueText = "850"
        #expect(editor.canSave)
        editor.isSaving = true
        #expect(!editor.canSave)
    }

    @Test func editorRejectsScaleFromAnotherProvider() {
        let editor = CreditScoreEditorState(provider: .equifax, existing: nil)
        editor.scale = .experian1250
        editor.valueText = "850"

        #expect(!editor.canSave)
    }

    @Test func editingPreservesStoredScaleUntilExplicitlyChanged() throws {
        let savedScore = try CreditScore(
            provider: .experian,
            scale: .experian999,
            value: 900,
            updatedAt: Date(timeIntervalSince1970: 1_800_000_000)
        )
        let editor = CreditScoreEditorState(provider: .experian, existing: savedScore)

        #expect(editor.scale == .experian999)
        #expect(editor.valueText == "900")
        #expect(editor.canSave)
        #expect(try editor.makeScore(updatedAt: Date()).scale == .experian999)
    }

    @Test func manualEntryAndUpdatePreserveProviderIdentity() async throws {
        let repository = InMemoryCreditScoreRepository()
        let date = Date(timeIntervalSince1970: 1_800_000_000)
        let store = CreditScoresStore(repository: repository, now: { date })

        await store.load()
        store.edit(.experian)
        let editor = try #require(store.editor)
        #expect(editor.scale == nil)
        editor.scale = .experian999
        editor.valueText = "900"
        await store.saveEditor()

        #expect(store.score(for: .experian)?.value == 900)
        #expect(store.score(for: .experian)?.scale == .experian999)
        #expect(store.score(for: .experian)?.updatedAt == date)

        store.edit(.experian)
        let updatedEditor = try #require(store.editor)
        updatedEditor.scale = .experian1250
        updatedEditor.valueText = "1100"
        await store.saveEditor()

        #expect(store.scores.count == 1)
        #expect(store.score(for: .experian)?.value == 1100)
        #expect(store.score(for: .experian)?.scale == .experian1250)
    }

    @Test func invalidValueDoesNotSave() async throws {
        let repository = InMemoryCreditScoreRepository()
        let store = CreditScoresStore(repository: repository)
        store.edit(.transUnion)
        let editor = try #require(store.editor)
        editor.scale = .transUnion710
        editor.valueText = "711"

        await store.saveEditor()

        #expect(store.scores.isEmpty)
        #expect(editor.errorMessage == "Enter a score from 0 to 710.")
        let persistedScores = try await repository.fetchScores()
        #expect(persistedScores.isEmpty)
    }
}

private actor InMemoryCreditScoreRepository: CreditScoreRepository {
    private var values: [CreditScoreProvider: CreditScore] = [:]

    func fetchScores() async throws -> [CreditScore] {
        values.values.sorted { $0.provider.displayName < $1.provider.displayName }
    }

    func save(_ score: CreditScore) async throws {
        values[score.provider] = score
    }
}
