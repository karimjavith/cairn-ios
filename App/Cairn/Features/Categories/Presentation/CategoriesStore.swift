//
//  CategoriesStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

@MainActor
@Observable
final class CategoriesStore {
    enum FeatureError: Error, Equatable {
        case categoryHasTransactions(CategoryID)
        case categoryHasBudgets(CategoryID)
    }

    private let categoryRepository: any CategoryRepository
    private let transactionRepository: any TransactionRepository
    private let budgetRepository: any BudgetRepository

    private(set) var categories: [Category] = []
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    private(set) var featureError: FeatureError?
    var editor: CategoryEditorState?
    var pendingDeletion: Category?

    init(
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository
    ) {
        self.categoryRepository = categoryRepository
        self.transactionRepository = transactionRepository
        self.budgetRepository = budgetRepository
    }

    var isEmpty: Bool {
        !isLoading && categories.isEmpty && errorMessage == nil
    }

    func loadCategories() async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await categoryRepository.fetchCategories()
            isLoading = false
        } catch {
            categories = []
            isLoading = false
            errorMessage = "Categories could not be loaded."
        }
    }

    func startCreateCategory() {
        editor = CategoryEditorState(category: nil)
    }

    func startEditing(_ category: Category) {
        editor = CategoryEditorState(category: category)
    }

    func dismissEditor() {
        editor = nil
    }

    func saveEditor() async {
        guard let editor else {
            return
        }

        editor.isSaving = true
        editor.errorMessage = nil

        do {
            let category = try editor.makeCategory()
            try await categoryRepository.save(category)
            self.editor = nil
            await loadCategories()
        } catch Category.ValidationError.emptyName {
            editor.isSaving = false
            editor.errorMessage = "Enter a category name."
        } catch {
            editor.isSaving = false
            editor.errorMessage = "Category could not be saved."
        }
    }

    func requestDelete(_ category: Category) {
        pendingDeletion = category
    }

    func cancelDelete() {
        pendingDeletion = nil
    }

    func confirmDelete() async {
        guard let category = pendingDeletion else {
            return
        }

        await confirmDelete(category)
    }

    func confirmDelete(_ category: Category) async {
        pendingDeletion = nil
        featureError = nil
        errorMessage = nil

        do {
            let transactions = try await transactionRepository.fetchTransactions(categoryID: category.id)

            guard transactions.isEmpty else {
                featureError = .categoryHasTransactions(category.id)
                errorMessage = "Category cannot be deleted while transactions use it."
                return
            }

            let budgets = try await budgetRepository.fetchBudgets()

            guard !budgets.contains(where: { $0.categoryID == category.id }) else {
                featureError = .categoryHasBudgets(category.id)
                errorMessage = "Category cannot be deleted while budgets use it."
                return
            }

            try await categoryRepository.deleteCategory(id: category.id)
            await loadCategories()
        } catch {
            errorMessage = "Category could not be deleted."
        }
    }
}

@MainActor
@Observable
final class CategoryEditorState: Identifiable {
    enum Mode: Equatable {
        case create
        case edit
    }

    let id: CategoryID
    let mode: Mode
    var name: String
    var kind: CategoryKind
    var isSaving = false
    var errorMessage: String?

    init(category: Category?) {
        if let category {
            id = category.id
            mode = .edit
            name = category.name
            kind = category.kind
        } else {
            id = CategoryID()
            mode = .create
            name = ""
            kind = .expense
        }
    }

    var title: String {
        switch mode {
        case .create:
            "New Category"
        case .edit:
            "Edit Category"
        }
    }

    func makeCategory() throws -> Category {
        try Category(
            id: id,
            name: name,
            kind: kind
        )
    }
}
