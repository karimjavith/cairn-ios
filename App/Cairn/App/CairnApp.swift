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
    #if DEBUG
    @State private var seedBootstrap: LocalSeedDataBootstrapCoordinator
    #endif

    init() {
        let modelContainer = Self.makeModelContainer()
        let accountRepository = SwiftDataAccountRepository(modelContainer: modelContainer)
        let categoryRepository = SwiftDataCategoryRepository(modelContainer: modelContainer)
        let transactionRepository = SwiftDataTransactionRepository(modelContainer: modelContainer)
        let budgetRepository = SwiftDataBudgetRepository(modelContainer: modelContainer)
        let goalRepository = SwiftDataGoalRepository(modelContainer: modelContainer)
        let recurringTransactionRepository = SwiftDataRecurringTransactionRepository(modelContainer: modelContainer)

        self.modelContainer = modelContainer
        dependencies = AppDependencies(
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            recurringTransactionRepository: recurringTransactionRepository,
            recurringTransactionCalendar: .autoupdatingCurrent,
            dashboardCalendar: .autoupdatingCurrent
        )

        #if DEBUG
        let seedLoader = LocalSeedDataLoader(
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            recurringTransactionRepository: recurringTransactionRepository
        )
        let seedConfiguration = LocalSeedDataBootstrap.configuration(isDebugBuild: true)
        _seedBootstrap = State(initialValue: LocalSeedDataBootstrapCoordinator(
            configuration: seedConfiguration,
            load: { configuration in
                try await seedLoader.loadIfNeeded(configuration: configuration)
            }
        ))
        #endif
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
            #if DEBUG
            LocalSeedDataBootstrapView(
                coordinator: seedBootstrap,
                dependencies: dependencies
            )
            #else
            RootView(dependencies: dependencies)
            #endif
        }
        .modelContainer(modelContainer)
    }
}
