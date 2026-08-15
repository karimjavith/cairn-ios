//
//  CairnApp.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import SwiftUI
import SwiftData

@main
struct CairnApp: App {
    private let modelContainer: ModelContainer
    private let dependencies: AppDependencies

    init() {
        let modelContainer = Self.makeModelContainer()

        self.modelContainer = modelContainer
        dependencies = AppDependencies(
            accountRepository: SwiftDataAccountRepository(modelContainer: modelContainer),
            categoryRepository: SwiftDataCategoryRepository(modelContainer: modelContainer),
            transactionRepository: SwiftDataTransactionRepository(modelContainer: modelContainer),
            budgetRepository: SwiftDataBudgetRepository(modelContainer: modelContainer)
        )
    }

    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            AccountRecord.self,
            BudgetRecord.self,
            CategoryRecord.self,
            GoalRecord.self,
            RecurringTransactionRecord.self,
            TransactionRecord.self
        ])
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SwiftData model container: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            RootView(dependencies: dependencies)
        }
        .modelContainer(modelContainer)
    }
}
