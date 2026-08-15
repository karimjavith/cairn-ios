//
//  GoalsStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct GoalsStoreTests {
    private let dotDecimalLocale = Locale(identifier: "en_GB")
    private let commaDecimalLocale = Locale(identifier: "de_DE")

    @Test func loadsGoalsAndDerivesProgressPreservingRepositoryOrder() async throws {
        let first = try makeGoal(name: "Emergency Fund", targetAmount: 1_000, currentAmount: 250)
        let second = try makeGoal(name: "Holiday", targetAmount: 500, currentAmount: 500)
        let firstProgress = try CalculateGoalProgress()(goal: first)
        let secondProgress = try CalculateGoalProgress()(goal: second)
        let progressProvider = GoalsFeatureProgressProvider(progressByID: [
            first.id: firstProgress,
            second.id: secondProgress
        ])
        let store = makeStore(
            goalRepository: GoalsFeatureGoalRepository(goals: [first, second]),
            progressProvider: progressProvider
        )

        await store.loadGoals()

        #expect(store.goals == [first, second])
        #expect(store.progress(for: first.id) == firstProgress)
        #expect(store.progress(for: second.id) == secondProgress)
        #expect(progressProvider.requestedGoalIDs() == [first.id, second.id])
        #expect(store.isEmpty == false)
    }

    @Test func emptyRepositoryProducesEmptyState() async {
        let store = makeStore()

        await store.loadGoals()

        #expect(store.goals == [])
        #expect(store.progressByGoalID == [:])
        #expect(store.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func repositoryLoadFailureIsSurfaced() async {
        let store = makeStore(
            goalRepository: GoalsFeatureGoalRepository(fetchError: GoalsFeatureRepositoryError.fetchFailed)
        )

        await store.loadGoals()

        #expect(store.goals == [])
        #expect(store.progressByGoalID == [:])
        #expect(store.errorMessage != nil)
    }

    @Test func progressFailureIsSurfacedWithoutFakeProgress() async throws {
        let goal = try makeGoal()
        let progressProvider = GoalsFeatureProgressProvider(error: GoalsFeatureRepositoryError.progressFailed)
        let store = makeStore(
            goalRepository: GoalsFeatureGoalRepository(goals: [goal]),
            progressProvider: progressProvider
        )

        await store.loadGoals()

        #expect(store.goals == [])
        #expect(store.progressByGoalID == [:])
        #expect(store.errorMessage != nil)
        #expect(progressProvider.requestedGoalIDs() == [goal.id])
    }

    @Test func validGoalSavesPreservingIDAndOptionalTargetDate() async throws {
        let targetDate = date(10_000)
        let goalRepository = GoalsFeatureGoalRepository()
        let store = makeStore(goalRepository: goalRepository)

        await store.loadGoals()
        store.startCreateGoal()
        let editor = try #require(store.editor)
        let goalID = editor.id
        editor.name = "  Emergency Fund  "
        editor.targetAmountText = "1000.50"
        editor.currentAmountText = "100.25"
        editor.currencyCode = "gbp"
        editor.hasTargetDate = true
        editor.targetDate = targetDate

        await store.saveEditor()

        let savedGoal = try #require(await goalRepository.savedGoals().first)
        #expect(savedGoal.id == goalID)
        #expect(savedGoal.name == "Emergency Fund")
        #expect(savedGoal.targetAmount == (try Money(amount: try decimal("1000.50"), currencyCode: "GBP")))
        #expect(savedGoal.currentAmount == (try Money(amount: try decimal("100.25"), currencyCode: "GBP")))
        #expect(savedGoal.targetDate == targetDate)
        #expect(store.editor == nil)
    }

    @Test func validGoalSavesNilTargetDate() async throws {
        let goalRepository = GoalsFeatureGoalRepository()
        let store = makeStore(goalRepository: goalRepository)

        await store.loadGoals()
        store.startCreateGoal()
        let editor = try #require(store.editor)
        editor.name = "House"
        editor.targetAmountText = "1000"
        editor.currentAmountText = "0"
        editor.currencyCode = "GBP"
        editor.hasTargetDate = false

        await store.saveEditor()

        let savedGoal = try #require(await goalRepository.savedGoals().first)
        #expect(savedGoal.targetDate == nil)
    }

    @Test func localizedHighPrecisionAmountsArePreservedOnCreate() async throws {
        let goalRepository = GoalsFeatureGoalRepository()
        let store = makeStore(
            goalRepository: goalRepository,
            locale: commaDecimalLocale
        )

        await store.loadGoals()
        store.startCreateGoal()
        let editor = try #require(store.editor)
        editor.name = "Precision"
        editor.targetAmountText = "10,123456789"
        editor.currentAmountText = "1,123456789"
        editor.currencyCode = "EUR"

        await store.saveEditor()

        let savedGoal = try #require(await goalRepository.savedGoals().first)
        #expect(savedGoal.targetAmount == (try Money(amount: try decimal("10.123456789"), currencyCode: "EUR")))
        #expect(savedGoal.currentAmount == (try Money(amount: try decimal("1.123456789"), currencyCode: "EUR")))
    }

    @Test func invalidDomainInputDoesNotSave() async throws {
        let goalRepository = GoalsFeatureGoalRepository()
        let store = makeStore(goalRepository: goalRepository)

        await store.loadGoals()
        store.startCreateGoal()
        let editor = try #require(store.editor)
        editor.name = "Too Far"
        editor.targetAmountText = "10"
        editor.currentAmountText = "11"
        editor.currencyCode = "GBP"

        await store.saveEditor()

        #expect(await goalRepository.savedGoals() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func saveFailureSurfaces() async throws {
        let goalRepository = GoalsFeatureGoalRepository(saveError: GoalsFeatureRepositoryError.saveFailed)
        let store = makeStore(goalRepository: goalRepository)

        await store.loadGoals()
        store.startCreateGoal()
        let editor = try #require(store.editor)
        editor.name = "House"
        editor.targetAmountText = "1000"
        editor.currentAmountText = "10"
        editor.currencyCode = "GBP"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func editPreservesGoalIDAndPersistsSupportedChanges() async throws {
        let goal = try makeGoal(
            name: "Old Name",
            targetAmount: 100,
            currentAmount: 10,
            targetDate: date(1_000)
        )
        let progressProvider = GoalsFeatureProgressProvider(progressByID: [
            goal.id: try CalculateGoalProgress()(goal: goal)
        ])
        let goalRepository = GoalsFeatureGoalRepository(goals: [goal])
        let store = makeStore(
            goalRepository: goalRepository,
            progressProvider: progressProvider
        )

        await store.loadGoals()
        store.startEditing(goal)
        let editor = try #require(store.editor)
        editor.name = "New Name"
        editor.targetAmountText = "250.75"
        editor.currentAmountText = "125.25"
        editor.currencyCode = "EUR"
        editor.hasTargetDate = true
        editor.targetDate = date(2_000)

        await store.saveEditor()

        let savedGoal = try #require(await goalRepository.savedGoals().first)
        #expect(savedGoal.id == goal.id)
        #expect(savedGoal.name == "New Name")
        #expect(savedGoal.targetAmount == (try Money(amount: try decimal("250.75"), currencyCode: "EUR")))
        #expect(savedGoal.currentAmount == (try Money(amount: try decimal("125.25"), currencyCode: "EUR")))
        #expect(savedGoal.targetDate == date(2_000))
        #expect(store.editor == nil)
    }

    @Test func editCanClearTargetDate() async throws {
        let goal = try makeGoal(targetDate: date(1_000))
        let progressProvider = GoalsFeatureProgressProvider(progressByID: [
            goal.id: try CalculateGoalProgress()(goal: goal)
        ])
        let goalRepository = GoalsFeatureGoalRepository(goals: [goal])
        let store = makeStore(
            goalRepository: goalRepository,
            progressProvider: progressProvider
        )

        await store.loadGoals()
        store.startEditing(goal)
        let editor = try #require(store.editor)
        editor.hasTargetDate = false

        await store.saveEditor()

        let savedGoal = try #require(await goalRepository.savedGoals().first)
        #expect(savedGoal.id == goal.id)
        #expect(savedGoal.targetDate == nil)
    }

    @Test func failedEditSaveSurfaces() async throws {
        let goal = try makeGoal()
        let progressProvider = GoalsFeatureProgressProvider(progressByID: [
            goal.id: try CalculateGoalProgress()(goal: goal)
        ])
        let goalRepository = GoalsFeatureGoalRepository(
            goals: [goal],
            saveError: GoalsFeatureRepositoryError.saveFailed
        )
        let store = makeStore(
            goalRepository: goalRepository,
            progressProvider: progressProvider
        )

        await store.loadGoals()
        store.startEditing(goal)
        let editor = try #require(store.editor)
        editor.name = "Edited"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
        #expect(await goalRepository.savedGoals() == [goal])
    }

    @Test func confirmedDeleteInvokesRepository() async throws {
        let goal = try makeGoal()
        let goalRepository = GoalsFeatureGoalRepository(goals: [goal])
        let store = makeStore(goalRepository: goalRepository)

        store.requestDelete(goal)
        await store.confirmDelete(goal)

        #expect(await goalRepository.deletedGoalIDs() == [goal.id])
        #expect(await goalRepository.deleteCallCount() == 1)
        #expect(store.pendingDeletion == nil)
    }

    @Test func cancelledDeleteDoesNotDelete() async throws {
        let goal = try makeGoal()
        let goalRepository = GoalsFeatureGoalRepository(goals: [goal])
        let store = makeStore(goalRepository: goalRepository)

        store.requestDelete(goal)
        store.cancelDelete()

        #expect(await goalRepository.deletedGoalIDs() == [])
        #expect(await goalRepository.deleteCallCount() == 0)
        #expect(store.pendingDeletion == nil)
    }

    @Test func deleteFailureSurfaces() async throws {
        let goal = try makeGoal()
        let goalRepository = GoalsFeatureGoalRepository(
            goals: [goal],
            deleteError: GoalsFeatureRepositoryError.deleteFailed
        )
        let store = makeStore(goalRepository: goalRepository)

        store.requestDelete(goal)
        await store.confirmDelete(goal)

        #expect(store.errorMessage != nil)
        #expect(await goalRepository.deletedGoalIDs() == [])
        #expect(await goalRepository.deleteCallCount() == 1)
    }

    @Test func selectionReachesGoalDetailState() async throws {
        let goal = try makeGoal(targetAmount: 100, currentAmount: 40)
        let progress = try CalculateGoalProgress()(goal: goal)
        let progressProvider = GoalsFeatureProgressProvider(progressByID: [goal.id: progress])
        let store = makeStore(
            goalRepository: GoalsFeatureGoalRepository(goals: [goal]),
            progressProvider: progressProvider
        )

        await store.loadGoals()
        store.selectDetail(goalID: goal.id)

        #expect(store.route == .detail(goal.id))
        #expect(store.goal(id: goal.id) == goal)
        #expect(store.progress(for: goal.id) == progress)
    }

    private func makeStore(
        goalRepository: GoalsFeatureGoalRepository = GoalsFeatureGoalRepository(),
        progressProvider: GoalsFeatureProgressProvider = GoalsFeatureProgressProvider(),
        locale: Locale? = nil
    ) -> GoalsStore {
        GoalsStore(
            goalRepository: goalRepository,
            calculateGoalProgress: { goal in
                try progressProvider.progress(goal: goal)
            },
            locale: locale ?? dotDecimalLocale
        )
    }

    private func makeGoal(
        id: GoalID = GoalID(),
        name: String = "Emergency Fund",
        targetAmount: Decimal = 100,
        currentAmount: Decimal = 10,
        currencyCode: String = "GBP",
        targetDate: Date? = nil
    ) throws -> Goal {
        try Goal(
            id: id,
            name: name,
            targetAmount: Money(amount: targetAmount, currencyCode: currencyCode),
            currentAmount: Money(amount: currentAmount, currencyCode: currencyCode),
            targetDate: targetDate
        )
    }

    private func date(_ offset: TimeInterval) -> Date {
        Date(timeIntervalSince1970: 1_786_080_000 + offset)
    }

    private func decimal(_ value: String) throws -> Decimal {
        try #require(Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")))
    }
}

private enum GoalsFeatureRepositoryError: Error, Equatable {
    case fetchFailed
    case saveFailed
    case deleteFailed
    case progressFailed
}

private actor GoalsFeatureGoalRepository: GoalRepository {
    private var goals: [Goal]
    private let fetchError: Error?
    private let saveError: Error?
    private let deleteError: Error?
    private var deletedIDs: [GoalID] = []
    private var deleteCount = 0

    init(
        goals: [Goal] = [],
        fetchError: Error? = nil,
        saveError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.goals = goals
        self.fetchError = fetchError
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchGoals() async throws -> [Goal] {
        if let fetchError {
            throw fetchError
        }

        return goals
    }

    func fetchGoal(id: GoalID) async throws -> Goal? {
        if let fetchError {
            throw fetchError
        }

        return goals.first { $0.id == id }
    }

    func save(_ goal: Goal) async throws {
        if let saveError {
            throw saveError
        }

        if let index = goals.firstIndex(where: { $0.id == goal.id }) {
            goals[index] = goal
        } else {
            goals.append(goal)
        }
    }

    func deleteGoal(id: GoalID) async throws {
        deleteCount += 1

        if let deleteError {
            throw deleteError
        }

        deletedIDs.append(id)
        goals.removeAll { $0.id == id }
    }

    func savedGoals() -> [Goal] {
        goals
    }

    func deletedGoalIDs() -> [GoalID] {
        deletedIDs
    }

    func deleteCallCount() -> Int {
        deleteCount
    }
}

private final class GoalsFeatureProgressProvider: @unchecked Sendable {
    private let progressByID: [GoalID: GoalProgress]
    private let error: Error?
    private var requestedIDs: [GoalID] = []

    init(
        progressByID: [GoalID: GoalProgress] = [:],
        error: Error? = nil
    ) {
        self.progressByID = progressByID
        self.error = error
    }

    func progress(goal: Goal) throws -> GoalProgress {
        requestedIDs.append(goal.id)

        if let error {
            throw error
        }

        guard let progress = progressByID[goal.id] else {
            return try CalculateGoalProgress()(goal: goal)
        }

        return progress
    }

    func requestedGoalIDs() -> [GoalID] {
        requestedIDs
    }
}
