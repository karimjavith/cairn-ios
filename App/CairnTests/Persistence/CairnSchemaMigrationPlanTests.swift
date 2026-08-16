//
//  CairnSchemaMigrationPlanTests.swift
//  CairnTests
//
//  Created by Codex on 16/08/2026.
//

import Foundation
import SwiftData
import Testing
@testable import Cairn

@MainActor
struct CairnSchemaMigrationPlanTests {
    @Test func currentVersionedSchemaContainsCurrentPersistenceModels() {
        let expectedModels: [any PersistentModel.Type] = [
            CairnSchemaV1.AccountRecord.self,
            CairnSchemaV1.BudgetRecord.self,
            CairnSchemaV1.CategoryRecord.self,
            CairnSchemaV1.GoalRecord.self,
            CairnSchemaV1.RecurringTransactionRecord.self,
            CairnSchemaV1.TransactionRecord.self
        ]

        #expect(CairnSchemaV1.versionIdentifier == Schema.Version(1, 0, 0))
        #expect(modelIdentifiers(CairnSchemaV1.models) == modelIdentifiers(expectedModels))
    }

    @Test func currentApplicationRecordNamesResolveToCurrentSchemaVersion() {
        #expect(ObjectIdentifier(AccountRecord.self) == ObjectIdentifier(CairnSchemaV1.AccountRecord.self))
        #expect(ObjectIdentifier(BudgetRecord.self) == ObjectIdentifier(CairnSchemaV1.BudgetRecord.self))
        #expect(ObjectIdentifier(CategoryRecord.self) == ObjectIdentifier(CairnSchemaV1.CategoryRecord.self))
        #expect(ObjectIdentifier(GoalRecord.self) == ObjectIdentifier(CairnSchemaV1.GoalRecord.self))
        #expect(
            ObjectIdentifier(RecurringTransactionRecord.self)
                == ObjectIdentifier(CairnSchemaV1.RecurringTransactionRecord.self)
        )
        #expect(ObjectIdentifier(TransactionRecord.self) == ObjectIdentifier(CairnSchemaV1.TransactionRecord.self))
    }

    @Test func migrationPlanExposesCurrentSchemaOnly() {
        #expect(schemaIdentifiers(CairnSchemaMigrationPlan.schemas) == schemaIdentifiers([CairnSchemaV1.self]))
        #expect(CairnSchemaMigrationPlan.stages.isEmpty)
    }

    @Test func versionedModelContainerCanBeCreated() throws {
        let container = try makeVersionedContainer(isStoredInMemoryOnly: true)

        #expect(container.schema.version == CairnSchemaV1.versionIdentifier)
        #expect(String(reflecting: container.migrationPlan) == String(reflecting: Optional(CairnSchemaMigrationPlan.self)))
    }

    @Test func currentRecordsCanBeInsertedFetchedAndMappedWithVersionedContainer() throws {
        let container = try makeVersionedContainer(isStoredInMemoryOnly: true)
        let context = ModelContext(container)
        let records = makeRecords()

        insert(records, into: context)
        try context.save()

        let account = try #require(try context.fetch(FetchDescriptor<AccountRecord>()).first?.account())
        let transaction = try #require(try context.fetch(FetchDescriptor<TransactionRecord>()).first?.transaction())
        let category = try #require(try context.fetch(FetchDescriptor<CategoryRecord>()).first?.category())
        let budget = try #require(try context.fetch(FetchDescriptor<BudgetRecord>()).first?.budget())
        let goal = try #require(try context.fetch(FetchDescriptor<GoalRecord>()).first?.goal())
        let recurringTransaction = try #require(
            try context.fetch(FetchDescriptor<RecurringTransactionRecord>()).first?.recurringTransaction()
        )

        #expect(account.id.rawValue == records.account.id)
        #expect(account.name == "Everyday")
        #expect(transaction.accountID.rawValue == records.account.id)
        #expect(transaction.categoryID?.rawValue == records.category.id)
        #expect(category.kind == .expense)
        #expect(budget.categoryID.rawValue == records.category.id)
        #expect(goal.name == "Emergency Fund")
        #expect(recurringTransaction.accountID.rawValue == records.account.id)
    }

    @Test func preVersioningStoreCanOpenWithVersionedMigrationPlan() throws {
        let storeURL = try copyPreVersioningFixtureToTemporaryStore()
        let container = try makeVersionedContainer(storeURL: storeURL)
        let context = ModelContext(container)

        let accountRecords = try context.fetch(FetchDescriptor<AccountRecord>())
        let categoryRecords = try context.fetch(FetchDescriptor<CategoryRecord>())
        let transactionRecords = try context.fetch(FetchDescriptor<TransactionRecord>())
        let budgetRecords = try context.fetch(FetchDescriptor<BudgetRecord>())
        let goalRecords = try context.fetch(FetchDescriptor<GoalRecord>())
        let recurringTransactionRecords = try context.fetch(FetchDescriptor<RecurringTransactionRecord>())

        #expect(accountRecords.count == 1)
        #expect(categoryRecords.count == 1)
        #expect(transactionRecords.count == 1)
        #expect(budgetRecords.count == 1)
        #expect(goalRecords.count == 1)
        #expect(recurringTransactionRecords.count == 1)

        let account = try #require(accountRecords.first).account()
        let category = try #require(categoryRecords.first).category()
        let transaction = try #require(transactionRecords.first).transaction()
        let budget = try #require(budgetRecords.first).budget()
        let goal = try #require(goalRecords.first).goal()
        let recurringTransaction = try #require(recurringTransactionRecords.first).recurringTransaction()

        #expect(account.id.rawValue == UUID(uuidString: "11111111-1111-1111-1111-111111111111"))
        #expect(account.type == .checking)
        #expect(account.openingBalance.amount == Decimal(string: "100.25"))
        #expect(account.openingBalance.currencyCode == "GBP")
        #expect(category.id.rawValue == UUID(uuidString: "22222222-2222-2222-2222-222222222222"))
        #expect(category.kind == .expense)
        #expect(transaction.id.rawValue == UUID(uuidString: "33333333-3333-3333-3333-333333333333"))
        #expect(transaction.accountID == account.id)
        #expect(transaction.categoryID == category.id)
        #expect(transaction.direction == .outflow)
        #expect(transaction.amount.amount == Decimal(string: "12.34"))
        #expect(transaction.amount.currencyCode == "GBP")
        #expect(transaction.memo == "Market")
        #expect(budget.id.rawValue == UUID(uuidString: "44444444-4444-4444-4444-444444444444"))
        #expect(budget.categoryID == category.id)
        #expect(budget.limit.amount == Decimal(string: "500.75"))
        #expect(budget.limit.currencyCode == "GBP")
        #expect(goal.id.rawValue == UUID(uuidString: "55555555-5555-5555-5555-555555555555"))
        #expect(goal.targetAmount.amount == Decimal(string: "1000.00"))
        #expect(goal.currentAmount.amount == Decimal(string: "250.50"))
        #expect(goal.targetAmount.currencyCode == "GBP")
        #expect(goal.currentAmount.currencyCode == "GBP")
        #expect(goal.targetDate == Date(timeIntervalSince1970: 1_798_675_200))
        #expect(
            recurringTransaction.id.rawValue
                == UUID(uuidString: "66666666-6666-6666-6666-666666666666")
        )
        #expect(recurringTransaction.accountID == account.id)
        #expect(recurringTransaction.direction == .inflow)
        #expect(recurringTransaction.amount.amount == Decimal(string: "25.125"))
        #expect(recurringTransaction.amount.currencyCode == "GBP")
        #expect(recurringTransaction.frequency == .monthly)
        #expect(recurringTransaction.endDate == nil)
        #expect(recurringTransaction.memo == nil)
    }

    private func makeVersionedContainer(
        isStoredInMemoryOnly: Bool = false,
        storeURL: URL? = nil
    ) throws -> ModelContainer {
        let schema = Schema(versionedSchema: CairnSchemaV1.self)
        let configuration: ModelConfiguration

        if let storeURL {
            configuration = ModelConfiguration(schema: schema, url: storeURL)
        } else {
            configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isStoredInMemoryOnly)
        }

        return try ModelContainer(
            for: schema,
            migrationPlan: CairnSchemaMigrationPlan.self,
            configurations: [configuration]
        )
    }

    private func temporaryStoreURL() -> URL {
        URL(filePath: NSTemporaryDirectory())
            .appending(path: "cairn-migration-\(UUID().uuidString)")
            .appendingPathExtension("store")
    }

    private func copyPreVersioningFixtureToTemporaryStore() throws -> URL {
        let destinationURL = temporaryStoreURL()
        let fixtureFiles = [
            "PreVersioningCairn.store",
            "PreVersioningCairn.store-shm",
            "PreVersioningCairn.store-wal"
        ]

        for filename in fixtureFiles {
            let sourceURL = try preVersioningFixtureURL(filename: filename)
            let destinationFileURL = destinationURL
                .deletingLastPathComponent()
                .appending(path: filename.replacingOccurrences(of: "PreVersioningCairn.store", with: destinationURL.lastPathComponent))
            try FileManager.default.copyItem(at: sourceURL, to: destinationFileURL)
        }

        return destinationURL
    }

    private func preVersioningFixtureURL(filename: String) throws -> URL {
        if let bundledURL = Bundle(for: CairnSchemaMigrationPlanTestsBundleMarker.self).url(
            forResource: filename,
            withExtension: nil,
            subdirectory: "Persistence/Fixtures/PreVersioningCairn"
        ) {
            return bundledURL
        }

        let sourceDirectory = URL(filePath: #filePath)
            .deletingLastPathComponent()
            .appending(path: "Fixtures/PreVersioningCairn")
        let sourceURL = sourceDirectory.appending(path: filename)

        guard FileManager.default.fileExists(atPath: sourceURL.path) else {
            throw PreVersioningFixtureError.missingFixture(filename)
        }

        return sourceURL
    }

    private func modelIdentifiers(_ models: [any PersistentModel.Type]) -> Set<ObjectIdentifier> {
        Set(models.map { ObjectIdentifier($0) })
    }

    private func schemaIdentifiers(_ schemas: [any VersionedSchema.Type]) -> Set<ObjectIdentifier> {
        Set(schemas.map { ObjectIdentifier($0) })
    }

    private func insert(_ records: CurrentRecords, into context: ModelContext) {
        context.insert(records.account)
        context.insert(records.category)
        context.insert(records.transaction)
        context.insert(records.budget)
        context.insert(records.goal)
        context.insert(records.recurringTransaction)
    }

    private func makeRecords() -> CurrentRecords {
        let accountID = UUID()
        let categoryID = UUID()

        return CurrentRecords(
            account: AccountRecord(
                id: accountID,
                name: "Everyday",
                type: "checking",
                currencyCode: "GBP",
                openingBalanceAmount: "100.25"
            ),
            category: CategoryRecord(
                id: categoryID,
                name: "Groceries",
                kind: "expense"
            ),
            transaction: TransactionRecord(
                id: UUID(),
                accountID: accountID,
                direction: "outflow",
                amount: "12.34",
                currencyCode: "GBP",
                occurredAt: Date(timeIntervalSince1970: 1_788_930_000),
                categoryID: categoryID,
                memo: "Market"
            ),
            budget: BudgetRecord(
                id: UUID(),
                categoryID: categoryID,
                limitAmount: "500",
                currencyCode: "GBP",
                startDate: Date(timeIntervalSince1970: 1_767_225_600),
                endDate: Date(timeIntervalSince1970: 1_769_904_000)
            ),
            goal: GoalRecord(
                id: UUID(),
                name: "Emergency Fund",
                targetAmount: "1000",
                targetCurrencyCode: "GBP",
                currentAmount: "250.50",
                currentCurrencyCode: "GBP",
                targetDate: Date(timeIntervalSince1970: 1_798_675_200)
            ),
            recurringTransaction: RecurringTransactionRecord(
                id: UUID(),
                accountID: accountID,
                direction: "outflow",
                amount: "25",
                currencyCode: "GBP",
                frequency: "monthly",
                startDate: Date(timeIntervalSince1970: 1_767_258_000),
                endDate: nil,
                memo: "Subscription"
            )
        )
    }
}

private struct CurrentRecords {
    let account: AccountRecord
    let category: CategoryRecord
    let transaction: TransactionRecord
    let budget: BudgetRecord
    let goal: GoalRecord
    let recurringTransaction: RecurringTransactionRecord
}

private final class CairnSchemaMigrationPlanTestsBundleMarker {}

private enum PreVersioningFixtureError: Error, Equatable {
    case missingFixture(String)
}
