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
    private let startupState: CairnAppStartupState
    #if DEBUG
    @State private var seedBootstrap: LocalSeedDataBootstrapCoordinator?
    #endif

    init() {
        do {
            let modelContainer = try Self.makeModelContainer()
            let dependencies = Self.makeDependencies(modelContainer: modelContainer)

            startupState = .ready(
                modelContainer: modelContainer,
                dependencies: dependencies
            )

            #if DEBUG
            _seedBootstrap = State(initialValue: Self.makeSeedBootstrap(
                dependencies: dependencies
            ))
            #endif
        } catch {
            startupState = .failed(Self.startupFailureMessage(for: error))

            #if DEBUG
            _seedBootstrap = State(initialValue: nil)
            #endif
        }
    }

    private static func makeDependencies(modelContainer: ModelContainer) -> AppDependencies {
        let accountRepository = SwiftDataAccountRepository(modelContainer: modelContainer)
        let categoryRepository = SwiftDataCategoryRepository(modelContainer: modelContainer)
        let transactionRepository = SwiftDataTransactionRepository(modelContainer: modelContainer)
        let budgetRepository = SwiftDataBudgetRepository(modelContainer: modelContainer)
        let goalRepository = SwiftDataGoalRepository(modelContainer: modelContainer)
        let recurringTransactionRepository = SwiftDataRecurringTransactionRepository(modelContainer: modelContainer)

        return AppDependencies(
            accountRepository: accountRepository,
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository,
            goalRepository: goalRepository,
            recurringTransactionRepository: recurringTransactionRepository,
            recurringTransactionCalendar: .autoupdatingCurrent,
            dashboardCalendar: .autoupdatingCurrent
        )
    }

    #if DEBUG
    private static func makeSeedBootstrap(
        dependencies: AppDependencies
    ) -> LocalSeedDataBootstrapCoordinator {
        let seedLoader = LocalSeedDataLoader(
            accountRepository: dependencies.accountRepository,
            categoryRepository: dependencies.categoryRepository,
            transactionRepository: dependencies.transactionRepository,
            budgetRepository: dependencies.budgetRepository,
            goalRepository: dependencies.goalRepository,
            recurringTransactionRepository: dependencies.recurringTransactionRepository
        )
        let seedConfiguration = LocalSeedDataBootstrap.configuration(isDebugBuild: true)

        return LocalSeedDataBootstrapCoordinator(
            configuration: seedConfiguration,
            load: { configuration in
                try await seedLoader.loadIfNeeded(configuration: configuration)
            }
        )
    }
    #endif

    private static func makeModelContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: CairnSchemaV1.self)
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        return try ModelContainer(
            for: schema,
            migrationPlan: CairnSchemaMigrationPlan.self,
            configurations: [configuration]
        )
    }

    static func startupFailureMessage(for error: any Error) -> String {
        "Cairn could not open its local data store. Your data was not reset or deleted."
    }

    var body: some Scene {
        WindowGroup {
            startupContent
        }
    }

    @ViewBuilder
    private var startupContent: some View {
        switch startupState {
        case let .ready(modelContainer, dependencies):
            #if DEBUG
            if let seedBootstrap {
                LocalSeedDataBootstrapView(
                    coordinator: seedBootstrap,
                    dependencies: dependencies
                )
                .modelContainer(modelContainer)
            } else {
                RootView(dependencies: dependencies)
                    .modelContainer(modelContainer)
            }
            #else
            RootView(dependencies: dependencies)
                .modelContainer(modelContainer)
            #endif
        case let .failed(message):
            AppStartupFailureView(message: message)
        }
    }
}

enum CairnAppStartupState {
    case ready(modelContainer: ModelContainer, dependencies: AppDependencies)
    case failed(String)
}

struct AppStartupFailureView: View {
    let message: String

    var body: some View {
        ContentUnavailableView {
            Label("Cairn Cannot Open", systemImage: "externaldrive.badge.exclamationmark")
        } description: {
            Text(message)
        }
    }
}
