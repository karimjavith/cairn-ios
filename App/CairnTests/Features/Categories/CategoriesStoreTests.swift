//
//  CategoriesStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct CategoriesStoreTests {
    @Test func loadsCategoriesPreservingRepositoryOrder() async throws {
        let groceries = try makeCategory(name: "Groceries", kind: .expense)
        let salary = try makeCategory(name: "Salary", kind: .income)
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [groceries, salary])
        let store = makeStore(categoryRepository: categoryRepository)

        await store.loadCategories()

        #expect(store.categories == [groceries, salary])
        #expect(store.isEmpty == false)
    }

    @Test func emptyRepositoryProducesEmptyState() async {
        let store = makeStore()

        await store.loadCategories()

        #expect(store.categories == [])
        #expect(store.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func repositoryLoadFailureIsSurfaced() async {
        let categoryRepository = CategoriesFeatureCategoryRepository(fetchCategoriesError: CategoriesFeatureRepositoryError.fetchFailed)
        let store = makeStore(categoryRepository: categoryRepository)

        await store.loadCategories()

        #expect(store.categories == [])
        #expect(store.errorMessage != nil)
        #expect(store.hasLoadFailed)
    }

    @Test func validCreatedCategoryIsSavedWithEditorCategoryID() async throws {
        let categoryRepository = CategoriesFeatureCategoryRepository()
        let store = makeStore(categoryRepository: categoryRepository)

        store.startCreateCategory()
        let editor = try #require(store.editor)
        let createdID = editor.id
        editor.name = "Groceries"
        editor.kind = .expense

        await store.saveEditor()

        let savedCategory = try #require(await categoryRepository.savedCategories().first)
        #expect(savedCategory.id == createdID)
        #expect(savedCategory.name == "Groceries")
        #expect(savedCategory.kind == .expense)
        #expect(store.editor == nil)
    }

    @Test func invalidCreateInputDoesNotSave() async throws {
        let categoryRepository = CategoriesFeatureCategoryRepository()
        let store = makeStore(categoryRepository: categoryRepository)

        store.startCreateCategory()
        let editor = try #require(store.editor)
        editor.name = "   "

        await store.saveEditor()

        #expect(await categoryRepository.savedCategories() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func repositorySaveFailureIsSurfaced() async throws {
        let categoryRepository = CategoriesFeatureCategoryRepository(saveError: CategoriesFeatureRepositoryError.saveFailed)
        let store = makeStore(categoryRepository: categoryRepository)

        store.startCreateCategory()
        let editor = try #require(store.editor)
        editor.name = "Groceries"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func editingPreservesCategoryIDAndPersistsChanges() async throws {
        let category = try makeCategory(name: "Old Name", kind: .expense)
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let store = makeStore(categoryRepository: categoryRepository)

        store.startEditing(category)
        let editor = try #require(store.editor)
        editor.name = "New Name"
        editor.kind = .income

        await store.saveEditor()

        let savedCategory = try #require(await categoryRepository.savedCategories().first)
        #expect(savedCategory.id == category.id)
        #expect(savedCategory.name == "New Name")
        #expect(savedCategory.kind == .income)
    }

    @Test func failedEditSaveDoesNotPretendSuccess() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(
            categories: [category],
            saveError: CategoriesFeatureRepositoryError.saveFailed
        )
        let store = makeStore(categoryRepository: categoryRepository)

        store.startEditing(category)
        let editor = try #require(store.editor)
        editor.name = "Renamed"
        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
        #expect(await categoryRepository.savedCategories() == [])
    }

    @Test func unreferencedCategoryCanBeDeleted() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository()
        let budgetRepository = CategoriesFeatureBudgetRepository()
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        await store.confirmDelete()

        #expect(await categoryRepository.deletedCategoryIDs() == [category.id])
        #expect(await transactionRepository.fetchTransactionsCallCount(categoryID: category.id) == 1)
        #expect(await budgetRepository.fetchBudgetsCallCount() == 1)
        #expect(store.featureError == nil)
    }

    @Test func confirmedDeleteUsesCapturedCategoryAfterPresentationStateClears() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository()
        let budgetRepository = CategoriesFeatureBudgetRepository()
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        store.cancelDelete()
        await store.confirmDelete(category)

        #expect(await categoryRepository.deletedCategoryIDs() == [category.id])
        #expect(await transactionRepository.fetchTransactionsCallCount(categoryID: category.id) == 1)
        #expect(await budgetRepository.fetchBudgetsCallCount() == 1)
        #expect(store.pendingDeletion == nil)
    }

    @Test func transactionReferencedCategoryCannotBeDeleted() async throws {
        let category = try makeCategory(name: "Groceries")
        let transaction = try makeTransaction(categoryID: category.id)
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository(transactionsByCategoryID: [
            category.id: [transaction]
        ])
        let budgetRepository = CategoriesFeatureBudgetRepository()
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        await store.confirmDelete()

        #expect(await categoryRepository.deletedCategoryIDs() == [])
        #expect(await budgetRepository.fetchBudgetsCallCount() == 0)
        #expect(store.featureError == .categoryHasTransactions(category.id))
        #expect(store.errorMessage != nil)
    }

    @Test func budgetReferencedCategoryCannotBeDeleted() async throws {
        let category = try makeCategory(name: "Groceries")
        let budget = try makeBudget(categoryID: category.id)
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository()
        let budgetRepository = CategoriesFeatureBudgetRepository(budgets: [budget])
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        await store.confirmDelete()

        #expect(await categoryRepository.deletedCategoryIDs() == [])
        #expect(await transactionRepository.fetchTransactionsCallCount(categoryID: category.id) == 1)
        #expect(await budgetRepository.fetchBudgetsCallCount() == 1)
        #expect(store.featureError == .categoryHasBudgets(category.id))
        #expect(store.errorMessage != nil)
    }

    @Test func transactionReferenceQueryFailureIsSurfaced() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository(
            fetchTransactionsError: CategoriesFeatureRepositoryError.fetchFailed
        )
        let budgetRepository = CategoriesFeatureBudgetRepository()
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        await store.confirmDelete()

        #expect(store.errorMessage != nil)
        #expect(await categoryRepository.deletedCategoryIDs() == [])
        #expect(await budgetRepository.fetchBudgetsCallCount() == 0)
    }

    @Test func budgetReferenceQueryFailureIsSurfaced() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository()
        let budgetRepository = CategoriesFeatureBudgetRepository(fetchBudgetsError: CategoriesFeatureRepositoryError.fetchFailed)
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        await store.confirmDelete()

        #expect(store.errorMessage != nil)
        #expect(await transactionRepository.fetchTransactionsCallCount(categoryID: category.id) == 1)
        #expect(await categoryRepository.deletedCategoryIDs() == [])
    }

    @Test func deleteFailureIsSurfaced() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(
            categories: [category],
            deleteError: CategoriesFeatureRepositoryError.deleteFailed
        )
        let store = makeStore(categoryRepository: categoryRepository)

        store.requestDelete(category)
        await store.confirmDelete()

        #expect(store.errorMessage != nil)
        #expect(await categoryRepository.deletedCategoryIDs() == [])
    }

    @Test func cancelledDeletePerformsNoRepositoryCalls() async throws {
        let category = try makeCategory(name: "Groceries")
        let categoryRepository = CategoriesFeatureCategoryRepository(categories: [category])
        let transactionRepository = CategoriesFeatureTransactionRepository()
        let budgetRepository = CategoriesFeatureBudgetRepository()
        let store = makeStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )

        store.requestDelete(category)
        store.cancelDelete()
        await store.confirmDelete()

        #expect(await categoryRepository.deletedCategoryIDs() == [])
        #expect(await transactionRepository.fetchTransactionsCallCount(categoryID: category.id) == 0)
        #expect(await budgetRepository.fetchBudgetsCallCount() == 0)
    }

    private func makeStore(
        categoryRepository: CategoriesFeatureCategoryRepository = CategoriesFeatureCategoryRepository(),
        transactionRepository: CategoriesFeatureTransactionRepository = CategoriesFeatureTransactionRepository(),
        budgetRepository: CategoriesFeatureBudgetRepository = CategoriesFeatureBudgetRepository()
    ) -> CategoriesStore {
        CategoriesStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        )
    }

    private func makeCategory(
        id: CategoryID = CategoryID(),
        name: String = "Groceries",
        kind: CategoryKind = .expense
    ) throws -> Cairn.Category {
        try Cairn.Category(
            id: id,
            name: name,
            kind: kind
        )
    }

    private func makeTransaction(categoryID: CategoryID) throws -> Transaction {
        try Transaction(
            accountID: AccountID(),
            direction: .outflow,
            amount: Money(amount: 10, currencyCode: "GBP"),
            occurredAt: Date(timeIntervalSince1970: 1_786_080_000),
            categoryID: categoryID
        )
    }

    private func makeBudget(categoryID: CategoryID) throws -> Budget {
        try Budget(
            categoryID: categoryID,
            limit: Money(amount: 100, currencyCode: "GBP"),
            period: BudgetPeriod(
                startDate: Date(timeIntervalSince1970: 1_786_080_000),
                endDate: Date(timeIntervalSince1970: 1_788_672_000)
            )
        )
    }
}

private enum CategoriesFeatureRepositoryError: Error {
    case fetchFailed
    case saveFailed
    case deleteFailed
}

private actor CategoriesFeatureCategoryRepository: CategoryRepository {
    private var categories: [Cairn.Category]
    private var saved: [Cairn.Category] = []
    private var deletedIDs: [CategoryID] = []
    private let fetchCategoriesError: Error?
    private let saveError: Error?
    private let deleteError: Error?

    init(
        categories: [Cairn.Category] = [],
        fetchCategoriesError: Error? = nil,
        saveError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.categories = categories
        self.fetchCategoriesError = fetchCategoriesError
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchCategories() async throws -> [Cairn.Category] {
        if let fetchCategoriesError {
            throw fetchCategoriesError
        }

        return categories
    }

    func fetchCategory(id: CategoryID) async throws -> Cairn.Category? {
        categories.first { $0.id == id }
    }

    func save(_ category: Cairn.Category) async throws {
        if let saveError {
            throw saveError
        }

        saved.append(category)

        if let index = categories.firstIndex(where: { $0.id == category.id }) {
            categories[index] = category
        } else {
            categories.append(category)
        }
    }

    func deleteCategory(id: CategoryID) async throws {
        if let deleteError {
            throw deleteError
        }

        deletedIDs.append(id)
        categories.removeAll { $0.id == id }
    }

    func savedCategories() -> [Cairn.Category] {
        saved
    }

    func deletedCategoryIDs() -> [CategoryID] {
        deletedIDs
    }
}

private actor CategoriesFeatureTransactionRepository: TransactionRepository {
    private let transactionsByCategoryID: [CategoryID: [Transaction]]
    private let fetchTransactionsError: Error?
    private var fetchTransactionCounts: [CategoryID: Int] = [:]
    private var saved: [Transaction] = []
    private var deletedIDs: [TransactionID] = []

    init(
        transactionsByCategoryID: [CategoryID: [Transaction]] = [:],
        fetchTransactionsError: Error? = nil
    ) {
        self.transactionsByCategoryID = transactionsByCategoryID
        self.fetchTransactionsError = fetchTransactionsError
    }

    func fetchTransactions(accountID: AccountID) async throws -> [Transaction] {
        []
    }

    func fetchTransactions(categoryID: CategoryID) async throws -> [Transaction] {
        fetchTransactionCounts[categoryID, default: 0] += 1

        if let fetchTransactionsError {
            throw fetchTransactionsError
        }

        return transactionsByCategoryID[categoryID] ?? []
    }

    func fetchTransactions(occurredFrom start: Date, occurredBefore end: Date) async throws -> [Transaction] {
        []
    }

    func fetchTransaction(id: TransactionID) async throws -> Transaction? {
        nil
    }

    func save(_ transaction: Transaction) async throws {
        saved.append(transaction)
    }

    func deleteTransaction(id: TransactionID) async throws {
        deletedIDs.append(id)
    }

    func fetchTransactionsCallCount(categoryID: CategoryID) -> Int {
        fetchTransactionCounts[categoryID, default: 0]
    }
}

private actor CategoriesFeatureBudgetRepository: BudgetRepository {
    private let budgets: [Budget]
    private let fetchBudgetsError: Error?
    private var fetchBudgetCount = 0
    private var saved: [Budget] = []
    private var deletedIDs: [BudgetID] = []

    init(
        budgets: [Budget] = [],
        fetchBudgetsError: Error? = nil
    ) {
        self.budgets = budgets
        self.fetchBudgetsError = fetchBudgetsError
    }

    func fetchBudgets() async throws -> [Budget] {
        fetchBudgetCount += 1

        if let fetchBudgetsError {
            throw fetchBudgetsError
        }

        return budgets
    }

    func fetchBudget(id: BudgetID) async throws -> Budget? {
        budgets.first { $0.id == id }
    }

    func save(_ budget: Budget) async throws {
        saved.append(budget)
    }

    func deleteBudget(id: BudgetID) async throws {
        deletedIDs.append(id)
    }

    func fetchBudgetsCallCount() -> Int {
        fetchBudgetCount
    }
}
