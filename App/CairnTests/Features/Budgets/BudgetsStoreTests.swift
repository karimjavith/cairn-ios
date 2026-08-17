//
//  BudgetsStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct BudgetsStoreTests {
    private let dotDecimalLocale = Locale(identifier: "en_GB")
    private let commaDecimalLocale = Locale(identifier: "de_DE")

    @Test func loadsBudgetsAndDerivesProgressPreservingRepositoryOrder() async throws {
        let category = try makeCategory(name: "Groceries")
        let first = try makeBudget(categoryID: category.id, limit: Money(amount: 200, currencyCode: "GBP"))
        let second = try makeBudget(categoryID: category.id, limit: Money(amount: 300, currencyCode: "GBP"))
        let firstProgress = try makeProgress(budget: first, spent: 50, remaining: 150)
        let secondProgress = try makeProgress(budget: second, spent: 75, remaining: 225)
        let progressProvider = BudgetsFeatureProgressProvider(progressByID: [
            first.id: firstProgress,
            second.id: secondProgress
        ])
        let store = makeStore(
            budgetRepository: BudgetsFeatureBudgetRepository(budgets: [first, second]),
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category]),
            progressProvider: progressProvider
        )

        await store.loadBudgets()

        #expect(store.budgets == [first, second])
        #expect(store.progress(for: first.id) == firstProgress)
        #expect(store.progress(for: second.id) == secondProgress)
        #expect(await progressProvider.requestedBudgetIDs() == [first.id, second.id])
        #expect(store.categoryName(for: category.id) == "Groceries")
        #expect(store.isEmpty == false)
    }

    @Test func emptyRepositoryProducesEmptyState() async {
        let store = makeStore()

        await store.loadBudgets()

        #expect(store.budgets == [])
        #expect(store.progressByBudgetID == [:])
        #expect(store.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func repositoryLoadFailureIsSurfaced() async {
        let store = makeStore(
            budgetRepository: BudgetsFeatureBudgetRepository(fetchError: BudgetsFeatureRepositoryError.fetchFailed)
        )

        await store.loadBudgets()

        #expect(store.budgets == [])
        #expect(store.progressByBudgetID == [:])
        #expect(store.errorMessage != nil)
        #expect(store.hasLoadFailed)
    }

    @Test func progressFailureIsSurfacedWithoutZeroSubstitution() async throws {
        let budget = try makeBudget()
        let progressProvider = BudgetsFeatureProgressProvider(error: BudgetsFeatureRepositoryError.progressFailed)
        let store = makeStore(
            budgetRepository: BudgetsFeatureBudgetRepository(budgets: [budget]),
            progressProvider: progressProvider
        )

        await store.loadBudgets()

        #expect(store.budgets == [])
        #expect(store.progressByBudgetID == [:])
        #expect(store.errorMessage != nil)
        #expect(await progressProvider.requestedBudgetIDs() == [budget.id])
    }

    @Test func validBudgetSavesPreservingIDCategoryAndPeriod() async throws {
        let category = try makeCategory()
        let budgetRepository = BudgetsFeatureBudgetRepository()
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category])
        )

        await store.loadBudgets()
        store.startCreateBudget()
        let editor = try #require(store.editor)
        let budgetID = editor.id
        let startDate = date(1_000)
        let endDate = date(2_000)
        editor.selectedCategoryID = category.id
        editor.limitText = "123.45"
        editor.currencyCode = "gbp"
        editor.startDate = startDate
        editor.endDate = endDate

        await store.saveEditor()

        let savedBudget = try #require(await budgetRepository.savedBudgets().first)
        #expect(savedBudget.id == budgetID)
        #expect(savedBudget.categoryID == category.id)
        #expect(savedBudget.limit == (try Money(amount: try decimal("123.45"), currencyCode: "GBP")))
        #expect(savedBudget.period == (try BudgetPeriod(startDate: startDate, endDate: endDate)))
        #expect(store.editor == nil)
    }

    @Test func localizedHighPrecisionLimitIsPreservedOnCreate() async throws {
        let category = try makeCategory()
        let budgetRepository = BudgetsFeatureBudgetRepository()
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category]),
            locale: commaDecimalLocale
        )

        await store.loadBudgets()
        store.startCreateBudget()
        let editor = try #require(store.editor)
        editor.limitText = "10,123456789"
        editor.currencyCode = "EUR"

        await store.saveEditor()

        let savedBudget = try #require(await budgetRepository.savedBudgets().first)
        #expect(savedBudget.limit == (try Money(amount: try decimal("10.123456789"), currencyCode: "EUR")))
    }

    @Test func invalidMoneyInputDoesNotSave() async throws {
        let category = try makeCategory()
        let budgetRepository = BudgetsFeatureBudgetRepository()
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category])
        )

        await store.loadBudgets()
        store.startCreateBudget()
        let editor = try #require(store.editor)
        editor.limitText = "bad amount"

        await store.saveEditor()

        #expect(await budgetRepository.savedBudgets() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func invalidPeriodInputDoesNotSave() async throws {
        let category = try makeCategory()
        let budgetRepository = BudgetsFeatureBudgetRepository()
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category])
        )

        await store.loadBudgets()
        store.startCreateBudget()
        let editor = try #require(store.editor)
        editor.limitText = "10"
        editor.startDate = date(2_000)
        editor.endDate = date(1_000)

        await store.saveEditor()

        #expect(await budgetRepository.savedBudgets() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func invalidBudgetInputDoesNotSave() async throws {
        let category = try makeCategory()
        let budgetRepository = BudgetsFeatureBudgetRepository()
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category])
        )

        await store.loadBudgets()
        store.startCreateBudget()
        let editor = try #require(store.editor)
        editor.limitText = "-1"

        await store.saveEditor()

        #expect(await budgetRepository.savedBudgets() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func saveFailureSurfaces() async throws {
        let category = try makeCategory()
        let budgetRepository = BudgetsFeatureBudgetRepository(saveError: BudgetsFeatureRepositoryError.saveFailed)
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category])
        )

        await store.loadBudgets()
        store.startCreateBudget()
        let editor = try #require(store.editor)
        editor.limitText = "10"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func editPreservesBudgetIDAndPersistsSupportedChanges() async throws {
        let oldCategory = try makeCategory(name: "Old")
        let newCategory = try makeCategory(name: "New")
        let budget = try makeBudget(
            categoryID: oldCategory.id,
            limit: Money(amount: 100, currencyCode: "GBP"),
            period: BudgetPeriod(startDate: date(1_000), endDate: date(2_000))
        )
        let budgetRepository = BudgetsFeatureBudgetRepository(budgets: [budget])
        let progressProvider = BudgetsFeatureProgressProvider(progressByID: [
            budget.id: try makeProgress(budget: budget, spent: 25, remaining: 75)
        ])
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [oldCategory, newCategory]),
            progressProvider: progressProvider
        )

        await store.loadBudgets()
        store.startEditing(budget)
        let editor = try #require(store.editor)
        editor.selectedCategoryID = newCategory.id
        editor.limitText = "250.75"
        editor.currencyCode = "EUR"
        editor.startDate = date(3_000)
        editor.endDate = date(4_000)

        await store.saveEditor()

        let savedBudget = try #require(await budgetRepository.savedBudgets().first)
        #expect(savedBudget.id == budget.id)
        #expect(savedBudget.categoryID == newCategory.id)
        #expect(savedBudget.limit == (try Money(amount: try decimal("250.75"), currencyCode: "EUR")))
        #expect(savedBudget.period == (try BudgetPeriod(startDate: date(3_000), endDate: date(4_000))))
        #expect(store.editor == nil)
    }

    @Test func failedEditSaveSurfaces() async throws {
        let category = try makeCategory()
        let budget = try makeBudget(categoryID: category.id)
        let budgetRepository = BudgetsFeatureBudgetRepository(
            budgets: [budget],
            saveError: BudgetsFeatureRepositoryError.saveFailed
        )
        let store = makeStore(
            budgetRepository: budgetRepository,
            categoryRepository: BudgetsFeatureCategoryRepository(categories: [category])
        )

        await store.loadBudgets()
        store.startEditing(budget)
        let editor = try #require(store.editor)
        editor.limitText = "20"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
        #expect(await budgetRepository.savedBudgets() == [budget])
    }

    @Test func confirmedDeleteInvokesRepository() async throws {
        let budget = try makeBudget()
        let budgetRepository = BudgetsFeatureBudgetRepository(budgets: [budget])
        let store = makeStore(budgetRepository: budgetRepository)

        store.requestDelete(budget)
        await store.confirmDelete(budget)

        #expect(await budgetRepository.deletedBudgetIDs() == [budget.id])
        #expect(await budgetRepository.deleteCallCount() == 1)
        #expect(store.pendingDeletion == nil)
    }

    @Test func cancelledDeleteDoesNotDelete() async throws {
        let budget = try makeBudget()
        let budgetRepository = BudgetsFeatureBudgetRepository(budgets: [budget])
        let store = makeStore(budgetRepository: budgetRepository)

        store.requestDelete(budget)
        store.cancelDelete()

        #expect(await budgetRepository.deletedBudgetIDs() == [])
        #expect(await budgetRepository.deleteCallCount() == 0)
        #expect(store.pendingDeletion == nil)
    }

    @Test func deleteFailureSurfaces() async throws {
        let budget = try makeBudget()
        let budgetRepository = BudgetsFeatureBudgetRepository(
            budgets: [budget],
            deleteError: BudgetsFeatureRepositoryError.deleteFailed
        )
        let store = makeStore(budgetRepository: budgetRepository)

        store.requestDelete(budget)
        await store.confirmDelete(budget)

        #expect(store.errorMessage != nil)
        #expect(await budgetRepository.deletedBudgetIDs() == [])
        #expect(await budgetRepository.deleteCallCount() == 1)
    }

    @Test func selectionReachesBudgetDetailState() async throws {
        let budget = try makeBudget()
        let progress = try makeProgress(budget: budget, spent: 10, remaining: 90)
        let progressProvider = BudgetsFeatureProgressProvider(progressByID: [budget.id: progress])
        let store = makeStore(
            budgetRepository: BudgetsFeatureBudgetRepository(budgets: [budget]),
            progressProvider: progressProvider
        )

        await store.loadBudgets()
        store.selectDetail(budgetID: budget.id)

        #expect(store.route == .detail(budget.id))
        #expect(store.budget(id: budget.id) == budget)
        #expect(store.progress(for: budget.id) == progress)
    }

    private func makeStore(
        budgetRepository: BudgetsFeatureBudgetRepository = BudgetsFeatureBudgetRepository(),
        categoryRepository: BudgetsFeatureCategoryRepository = BudgetsFeatureCategoryRepository(),
        progressProvider: BudgetsFeatureProgressProvider = BudgetsFeatureProgressProvider(),
        locale: Locale? = nil
    ) -> BudgetsStore {
        BudgetsStore(
            budgetRepository: budgetRepository,
            categoryRepository: categoryRepository,
            calculateBudgetProgress: { budgetID in
                try await progressProvider.progress(budgetID: budgetID)
            },
            locale: locale ?? dotDecimalLocale
        )
    }

    private func makeBudget(
        id: BudgetID = BudgetID(),
        categoryID: CategoryID = CategoryID(),
        limit: Money? = nil,
        period: BudgetPeriod? = nil
    ) throws -> Budget {
        try Budget(
            id: id,
            categoryID: categoryID,
            limit: limit ?? Money(amount: 100, currencyCode: "GBP"),
            period: period ?? BudgetPeriod(startDate: date(1_000), endDate: date(2_000))
        )
    }

    private func makeProgress(
        budget: Budget,
        spent: Decimal,
        remaining: Decimal
    ) throws -> BudgetProgress {
        try BudgetProgress(
            budget: budget,
            spent: Money(amount: spent, currencyCode: budget.limit.currencyCode),
            remaining: Money(amount: remaining, currencyCode: budget.limit.currencyCode)
        )
    }

    private func makeCategory(
        id: CategoryID = CategoryID(),
        name: String = "Groceries"
    ) throws -> Cairn.Category {
        try Cairn.Category(id: id, name: name, kind: .expense)
    }

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_786_080_000 + offset)
    }

    private func decimal(_ value: String) throws -> Decimal {
        try #require(Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")))
    }
}

private enum BudgetsFeatureRepositoryError: Error, Equatable {
    case fetchFailed
    case saveFailed
    case deleteFailed
    case progressFailed
}

private actor BudgetsFeatureBudgetRepository: BudgetRepository {
    private var budgets: [Budget]
    private let fetchError: Error?
    private let saveError: Error?
    private let deleteError: Error?
    private var deletedIDs: [BudgetID] = []
    private var deleteCount = 0

    init(
        budgets: [Budget] = [],
        fetchError: Error? = nil,
        saveError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.budgets = budgets
        self.fetchError = fetchError
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchBudgets() async throws -> [Budget] {
        if let fetchError {
            throw fetchError
        }

        return budgets
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        if let fetchError {
            throw fetchError
        }

        return budgets.first { $0.id == id }
    }

    func save(_ budget: Budget) async throws {
        if let saveError {
            throw saveError
        }

        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
        } else {
            budgets.append(budget)
        }
    }

    func deleteBudget(id: BudgetID) async throws {
        deleteCount += 1

        if let deleteError {
            throw deleteError
        }

        deletedIDs.append(id)
        budgets.removeAll { $0.id == id }
    }

    func savedBudgets() -> [Budget] {
        budgets
    }

    func deletedBudgetIDs() -> [BudgetID] {
        deletedIDs
    }

    func deleteCallCount() -> Int {
        deleteCount
    }
}

private actor BudgetsFeatureCategoryRepository: CategoryRepository {
    private let categories: [Cairn.Category]
    private let fetchError: Error?

    init(
        categories: [Cairn.Category] = [],
        fetchError: Error? = nil
    ) {
        self.categories = categories
        self.fetchError = fetchError
    }

    func fetchCategories() async throws -> [Cairn.Category] {
        if let fetchError {
            throw fetchError
        }

        return categories
    }

    func fetchCategory(id: CategoryID) async throws -> Cairn.Category? {
        if let fetchError {
            throw fetchError
        }

        return categories.first { $0.id == id }
    }

    func save(_ category: Cairn.Category) async throws {}

    func deleteCategory(id: CategoryID) async throws {}
}

private actor BudgetsFeatureProgressProvider {
    private let progressByID: [BudgetID: BudgetProgress]
    private let error: Error?
    private var requestedIDs: [BudgetID] = []

    init(
        progressByID: [BudgetID: BudgetProgress] = [:],
        error: Error? = nil
    ) {
        self.progressByID = progressByID
        self.error = error
    }

    func progress(budgetID: BudgetID) async throws -> BudgetProgress {
        requestedIDs.append(budgetID)

        if let error {
            throw error
        }

        guard let progress = progressByID[budgetID] else {
            throw BudgetsFeatureRepositoryError.progressFailed
        }

        return progress
    }

    func requestedBudgetIDs() -> [BudgetID] {
        requestedIDs
    }
}
