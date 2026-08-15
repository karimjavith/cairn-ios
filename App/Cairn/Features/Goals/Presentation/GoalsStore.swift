//
//  GoalsStore.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Observation

typealias GoalProgressProvider = @Sendable (Goal) throws -> GoalProgress

@MainActor
@Observable
final class GoalsStore {
    enum Route: Hashable {
        case detail(GoalID)
    }

    private let goalRepository: any GoalRepository
    private let calculateGoalProgress: GoalProgressProvider
    private let locale: Locale

    private(set) var goals: [Goal] = []
    private(set) var progressByGoalID: [GoalID: GoalProgress] = [:]
    private(set) var isLoading = false
    private(set) var errorMessage: String?
    var editor: GoalEditorState?
    var pendingDeletion: Goal?
    var route: Route?

    init(
        goalRepository: any GoalRepository,
        calculateGoalProgress: @escaping GoalProgressProvider,
        locale: Locale = .current
    ) {
        self.goalRepository = goalRepository
        self.calculateGoalProgress = calculateGoalProgress
        self.locale = locale
    }

    var isEmpty: Bool {
        !isLoading && goals.isEmpty && errorMessage == nil
    }

    func loadGoals() async {
        isLoading = true
        errorMessage = nil

        do {
            let loadedGoals = try await goalRepository.fetchGoals()
            var loadedProgress: [GoalID: GoalProgress] = [:]

            for goal in loadedGoals {
                loadedProgress[goal.id] = try calculateGoalProgress(goal)
            }

            goals = loadedGoals
            progressByGoalID = loadedProgress
            isLoading = false
        } catch {
            goals = []
            progressByGoalID = [:]
            isLoading = false
            errorMessage = "Goals could not be loaded."
        }
    }

    func startCreateGoal() {
        editor = GoalEditorState(goal: nil, locale: locale)
    }

    func startEditing(_ goal: Goal) {
        editor = GoalEditorState(goal: goal, locale: locale)
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
            let goal = try editor.makeGoal()
            try await goalRepository.save(goal)
            self.editor = nil
            await loadGoals()
        } catch GoalMoneyTextParser.Error.empty {
            editor.isSaving = false
            editor.errorMessage = "Enter an amount."
        } catch GoalMoneyTextParser.Error.malformed {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid amount."
        } catch MoneyError.invalidCurrencyCode {
            editor.isSaving = false
            editor.errorMessage = "Enter a valid currency code."
        } catch Goal.ValidationError.emptyName {
            editor.isSaving = false
            editor.errorMessage = "Enter a goal name."
        } catch Goal.ValidationError.negativeTargetAmount {
            editor.isSaving = false
            editor.errorMessage = "Target amount cannot be negative."
        } catch Goal.ValidationError.negativeCurrentAmount {
            editor.isSaving = false
            editor.errorMessage = "Current amount cannot be negative."
        } catch Goal.ValidationError.currencyMismatch {
            editor.isSaving = false
            editor.errorMessage = "Goal amounts must use the same currency."
        } catch Goal.ValidationError.currentAmountExceedsTargetAmount {
            editor.isSaving = false
            editor.errorMessage = "Current amount cannot exceed target amount."
        } catch {
            editor.isSaving = false
            editor.errorMessage = "Goal could not be saved."
        }
    }

    func requestDelete(_ goal: Goal) {
        pendingDeletion = goal
    }

    func cancelDelete() {
        pendingDeletion = nil
    }

    func confirmDelete(_ goal: Goal) async {
        pendingDeletion = nil
        errorMessage = nil

        do {
            try await goalRepository.deleteGoal(id: goal.id)
            route = nil
            await loadGoals()
        } catch {
            errorMessage = "Goal could not be deleted."
        }
    }

    func selectDetail(goalID: GoalID) {
        route = .detail(goalID)
    }

    func goal(id: GoalID) -> Goal? {
        goals.first { $0.id == id }
    }

    func progress(for goalID: GoalID) -> GoalProgress? {
        progressByGoalID[goalID]
    }
}

@MainActor
@Observable
final class GoalEditorState: Identifiable {
    enum Mode: Equatable {
        case create
        case edit
    }

    let id: GoalID
    let mode: Mode
    private let locale: Locale
    var name: String
    var targetAmountText: String
    var currentAmountText: String
    var currencyCode: String
    var hasTargetDate: Bool
    var targetDate: Date
    var isSaving = false
    var errorMessage: String?

    init(
        goal: Goal?,
        locale: Locale = .current
    ) {
        self.locale = locale

        if let goal {
            id = goal.id
            mode = .edit
            name = goal.name
            targetAmountText = GoalMoneyFormatter.decimalText(goal.targetAmount.amount, locale: locale)
            currentAmountText = GoalMoneyFormatter.decimalText(goal.currentAmount.amount, locale: locale)
            currencyCode = goal.targetAmount.currencyCode
            hasTargetDate = goal.targetDate != nil
            targetDate = goal.targetDate ?? Date()
        } else {
            id = GoalID()
            mode = .create
            name = ""
            targetAmountText = ""
            currentAmountText = ""
            currencyCode = Locale.current.currency?.identifier ?? "USD"
            hasTargetDate = false
            targetDate = Date()
        }
    }

    var title: String {
        switch mode {
        case .create:
            "New Goal"
        case .edit:
            "Edit Goal"
        }
    }

    func makeGoal() throws -> Goal {
        let targetAmount = try GoalMoneyTextParser.parse(targetAmountText, locale: locale)
        let currentAmount = try GoalMoneyTextParser.parse(currentAmountText, locale: locale)
        let targetMoney = try Money(amount: targetAmount, currencyCode: currencyCode)
        let currentMoney = try Money(amount: currentAmount, currencyCode: currencyCode)

        return try Goal(
            id: id,
            name: name,
            targetAmount: targetMoney,
            currentAmount: currentMoney,
            targetDate: hasTargetDate ? targetDate : nil
        )
    }
}
