//
//  BudgetsStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

typealias BudgetProgressProvider = @Sendable (BudgetID) async throws -> BudgetProgress

@MainActor
@Observable
final class BudgetsStore {
    enum Route: Hashable {
        case detail(BudgetID)
    }

    private let budgetRepository: any BudgetRepository
    private let categoryRepository: any CategoryRepository
    private let calculateBudgetProgress: BudgetProgressProvider
    private let locale: Locale

    private(set) var budgets: [Budget] = []
    private(set) var categories: [Category] = []
    private(set) var progressByBudgetID: [BudgetID: BudgetProgress] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var editor: BudgetEditorState?
    var pendingDeletion: Budget?
    var route: Route?

    init(
        budgetRepository: any BudgetRepository,
        categoryRepository: any CategoryRepository,
        calculateBudgetProgress: @escaping BudgetProgressProvider,
        locale: Locale = .current
    ) {
        self.budgetRepository = budgetRepository
        self.categoryRepository = categoryRepository
        self.calculateBudgetProgress = calculateBudgetProgress
        self.locale = locale
    }

    var isEmpty: Bool {
        !isLoading && budgets.isEmpty && errorMessage == nil
    }

    var hasLoadFailed: Bool {
        !isLoading && budgets.isEmpty && categories.isEmpty && progressByBudgetID.isEmpty && errorMessage != nil
    }

    func loadBudgets() async {
        isLoading = true
        errorMessage = nil

        do {
            categories = try await categoryRepository.fetchCategories()
            let loadedBudgets = try await budgetRepository.fetchBudgets()
            var loadedProgress: [BudgetID: BudgetProgress] = [:]

            for budget in loadedBudgets {
                loadedProgress[budget.id] = try await calculateBudgetProgress(budget.id)
            }

            budgets = loadedBudgets
            progressByBudgetID = loadedProgress
            isLoading = false
        } catch {
            budgets = []
            categories = []
            progressByBudgetID = [:]
            isLoading = false
            errorMessage = "Budgets could not be loaded."
        }
    }

    func startCreateBudget() {
        editor = BudgetEditorState(
            budget: nil,
            categories: categories,
            locale: locale
        )
    }

    func startEditing(_ budget: Budget) {
        editor = BudgetEditorState(
            budget: budget,
            categories: categories,
            locale: locale
        )
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
            let budget = try editor.makeBudget()
            try await budgetRepository.save(budget)
            self.editor = nil
            await loadBudgets()
        } catch BudgetMoneyTextParser.Error.empty {
            editor.isSaving = false
            editor.errorMessage = "Enter a limit."
        } catch BudgetMoneyTextParser.Error.malformed {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid limit."
        } catch BudgetEditorState.ValidationError.missingCategory {
            editor.isSaving = false
            editor.errorMessage = "Select a category."
        } catch BudgetEditorState.ValidationError.invalidCategory {
            editor.isSaving = false
            editor.errorMessage = "Select a valid category."
        } catch MoneyError.invalidCurrencyCode {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid currency code."
        } catch BudgetPeriod.ValidationError.invalidDateRange {
            editor.isSaving = false
            editor.errorMessage = "End date must be after start date."
        } catch Budget.ValidationError.negativeLimit {
            editor.isSaving = false
            editor.errorMessage = "Limit cannot be negative."
        } catch {
            editor.isSaving = false
            editor.errorMessage = "Budget could not be saved."
        }
    }

    func requestDelete(_ budget: Budget) {
        pendingDeletion = budget
    }

    func cancelDelete() {
        pendingDeletion = nil
    }

    func confirmDelete(_ budget: Budget) async {
        pendingDeletion = nil
        errorMessage = nil

        do {
            try await budgetRepository.deleteBudget(id: budget.id)
            route = nil
            await loadBudgets()
        } catch {
            errorMessage = "Budget could not be deleted."
        }
    }

    func selectDetail(budgetID: BudgetID) {
        route = .detail(budgetID)
    }

    func budget(id: BudgetID) -> Budget? {
        budgets.first { $0.id == id }
    }

    func progress(for budgetID: BudgetID) -> BudgetProgress? {
        progressByBudgetID[budgetID]
    }

    func categoryName(for categoryID: CategoryID) -> String {
        categories.first { $0.id == categoryID }?.name ?? "Unknown Category"
    }
}

@MainActor
@Observable
final class BudgetEditorState: Identifiable {
    enum Mode: Equatable {
        case create
        case edit
    }

    enum ValidationError: Error, Equatable {
        case missingCategory
        case invalidCategory
    }

    let id: BudgetID
    let mode: Mode
    let categories: [Category]
    private let locale: Locale
    var selectedCategoryID: CategoryID?
    var limitText: String
    var currencyCode: String
    var startDate: Date
    var endDate: Date
    var isSaving = false
    var errorMessage: String?

    init(
        budget: Budget?,
        categories: [Category],
        locale: Locale = .current
    ) {
        self.categories = categories
        self.locale = locale

        if let budget {
            id = budget.id
            mode = .edit
            selectedCategoryID = budget.categoryID
            limitText = BudgetMoneyFormatter.decimalText(budget.limit.amount, locale: locale)
            currencyCode = budget.limit.currencyCode
            startDate = budget.period.startDate
            endDate = budget.period.endDate
        } else {
            let defaultPeriod = Self.defaultPeriod()

            id = BudgetID()
            mode = .create
            selectedCategoryID = categories.first?.id
            limitText = ""
            currencyCode = Locale.current.currency?.identifier ?? "USD"
            startDate = defaultPeriod.startDate
            endDate = defaultPeriod.endDate
        }
    }

    var title: String {
        switch mode {
        case .create:
            "New Budget"
        case .edit:
            "Edit Budget"
        }
    }

    func makeBudget() throws -> Budget {
        guard let selectedCategoryID else {
            throw ValidationError.missingCategory
        }

        guard categories.contains(where: { $0.id == selectedCategoryID }) else {
            throw ValidationError.invalidCategory
        }

        let limitAmount = try BudgetMoneyTextParser.parse(limitText, locale: locale)
        let limit = try Money(amount: limitAmount, currencyCode: currencyCode)
        let period = try BudgetPeriod(startDate: startDate, endDate: endDate)

        return try Budget(
            id: id,
            categoryID: selectedCategoryID,
            limit: limit,
            period: period
        )
    }

    private static func defaultPeriod() -> BudgetPeriod {
        let calendar = Calendar.current
        let now = Date()

        if let interval = calendar.dateInterval(of: .month, for: now) {
            return try! BudgetPeriod(startDate: interval.start, endDate: interval.end)
        }

        let endDate = calendar.date(byAdding: .month, value: 1, to: now) ?? now.addingTimeInterval(2_592_000)
        return try! BudgetPeriod(startDate: now, endDate: endDate)
    }
}
