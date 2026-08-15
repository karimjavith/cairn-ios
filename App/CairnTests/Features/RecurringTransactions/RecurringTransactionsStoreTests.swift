//
//  RecurringTransactionsStoreTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct RecurringTransactionsStoreTests {
    private let dotDecimalLocale = Locale(identifier: "en_GB")
    private let commaDecimalLocale = Locale(identifier: "de_DE")

    @Test func loadsRecurringTransactionsPreservingRepositoryOrder() async throws {
        let account = try makeAccount()
        let first = try makeRecurringTransaction(accountID: account.id, startDate: date(1_000))
        let second = try makeRecurringTransaction(accountID: account.id, startDate: date(2_000))
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [first, second]
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()

        #expect(store.recurringTransactions == [first, second])
        #expect(store.isEmpty == false)
        #expect(store.errorMessage == nil)
    }

    @Test func emptyRepositoryProducesEmptyState() async {
        let store = makeStore()

        await store.loadRecurringTransactions()

        #expect(store.recurringTransactions == [])
        #expect(store.nextOccurrenceByRecurringTransactionID == [:])
        #expect(store.isEmpty)
        #expect(store.errorMessage == nil)
    }

    @Test func repositoryLoadFailureIsSurfaced() async {
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                fetchError: RecurringTransactionsFeatureError.fetchFailed
            )
        )

        await store.loadRecurringTransactions()

        #expect(store.recurringTransactions == [])
        #expect(store.nextOccurrenceByRecurringTransactionID == [:])
        #expect(store.errorMessage != nil)
    }

    @Test func accountDisplayMetadataResolves() async throws {
        let account = try makeAccount(name: "Everyday")
        let recurringTransaction = try makeRecurringTransaction(accountID: account.id)
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [recurringTransaction]
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()

        #expect(store.accountName(for: account.id) == "Everyday")
        #expect(store.accountName(for: AccountID()) == "Unknown Account")
    }

    @Test func nextOccurrenceIsDerivedForEachRecurringTransaction() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(
            accountID: account.id,
            frequency: .daily,
            startDate: utcDate(year: 2026, month: 1, day: 1)
        )
        let nextOccurrenceProvider = RecurringTransactionsFeatureNextOccurrenceProvider()
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [recurringTransaction]
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account]),
            nextOccurrenceProvider: { recurringTransaction, calendar, referenceDate in
                try nextOccurrenceProvider.provider(
                    recurringTransaction: recurringTransaction,
                    calendar: calendar,
                    referenceDate: referenceDate
                )
            },
            referenceDate: { utcDate(year: 2026, month: 1, day: 3) }
        )

        await store.loadRecurringTransactions()

        #expect(store.nextOccurrence(for: recurringTransaction.id) == utcDate(year: 2026, month: 1, day: 4))
        #expect(nextOccurrenceProvider.requests.map(\.recurringTransactionID) == [recurringTransaction.id])
    }

    @Test func schedulingFailureIsSurfacedWithoutFakeNextOccurrence() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(accountID: account.id)
        let nextOccurrenceProvider = RecurringTransactionsFeatureNextOccurrenceProvider(
            error: RecurringTransactionsFeatureError.scheduleFailed
        )
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [recurringTransaction]
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account]),
            nextOccurrenceProvider: { recurringTransaction, calendar, referenceDate in
                try nextOccurrenceProvider.provider(
                    recurringTransaction: recurringTransaction,
                    calendar: calendar,
                    referenceDate: referenceDate
                )
            }
        )

        await store.loadRecurringTransactions()

        #expect(store.recurringTransactions == [])
        #expect(store.nextOccurrenceByRecurringTransactionID == [:])
        #expect(store.errorMessage != nil)
    }

    @Test func validRecurringTransactionSavesPreservingValues() async throws {
        let account = try makeAccount(currencyCode: "GBP")
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository()
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account]),
            locale: dotDecimalLocale
        )

        await store.loadRecurringTransactions()
        store.startCreateRecurringTransaction()
        let editor = try #require(store.editor)
        let recurringTransactionID = editor.id
        editor.selectedAccountID = account.id
        editor.direction = .outflow
        editor.amountText = "123.45"
        editor.frequency = .weekly
        editor.startDate = date(1_000)
        editor.hasEndDate = true
        editor.endDate = date(2_000)
        editor.memo = "  Rent\n"

        await store.saveEditor()

        let saved = try #require(await recurringTransactionRepository.savedRecurringTransactions().first)
        #expect(saved.id == recurringTransactionID)
        #expect(saved.accountID == account.id)
        #expect(saved.direction == .outflow)
        #expect(saved.amount == (try Money(amount: try decimal("123.45"), currencyCode: "GBP")))
        #expect(saved.frequency == .weekly)
        #expect(saved.startDate == date(1_000))
        #expect(saved.endDate == date(2_000))
        #expect(saved.memo == "Rent")
        #expect(store.editor == nil)
    }

    @Test func localizedFractionalAmountIsPreservedOnCreate() async throws {
        let account = try makeAccount(currencyCode: "EUR")
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository()
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account]),
            locale: commaDecimalLocale
        )

        await store.loadRecurringTransactions()
        store.startCreateRecurringTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10,123456789"

        await store.saveEditor()

        let saved = try #require(await recurringTransactionRepository.savedRecurringTransactions().first)
        #expect(saved.amount == (try Money(amount: try decimal("10.123456789"), currencyCode: "EUR")))
    }

    @Test func createPreservesNilEndDate() async throws {
        let account = try makeAccount()
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository()
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.startCreateRecurringTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10"
        editor.hasEndDate = false

        await store.saveEditor()

        let saved = try #require(await recurringTransactionRepository.savedRecurringTransactions().first)
        #expect(saved.endDate == nil)
    }

    @Test func invalidInputDoesNotSave() async throws {
        let account = try makeAccount()
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository()
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.startCreateRecurringTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "bad amount"

        await store.saveEditor()

        #expect(await recurringTransactionRepository.savedRecurringTransactions() == [])
        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func repositorySaveFailureSurfaces() async throws {
        let account = try makeAccount()
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                saveError: RecurringTransactionsFeatureError.saveFailed
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.startCreateRecurringTransaction()
        let editor = try #require(store.editor)
        editor.amountText = "10"

        await store.saveEditor()

        #expect(editor.errorMessage != nil)
        #expect(store.editor != nil)
    }

    @Test func editPreservesRecurringTransactionIDAndPersistsSupportedChanges() async throws {
        let oldAccount = try makeAccount(name: "Old", currencyCode: "GBP")
        let newAccount = try makeAccount(name: "New", currencyCode: "EUR")
        let recurringTransaction = try makeRecurringTransaction(
            accountID: oldAccount.id,
            direction: .outflow,
            amount: Money(amount: 10, currencyCode: "GBP"),
            frequency: .monthly,
            startDate: date(1_000),
            endDate: nil,
            memo: "Old memo"
        )
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository(
            recurringTransactions: [recurringTransaction]
        )
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [oldAccount, newAccount]),
            locale: dotDecimalLocale
        )

        await store.loadRecurringTransactions()
        store.startEditing(recurringTransaction)
        let editor = try #require(store.editor)
        editor.selectedAccountID = newAccount.id
        editor.direction = .inflow
        editor.amountText = "123.456"
        editor.frequency = .yearly
        editor.startDate = date(2_000)
        editor.hasEndDate = true
        editor.endDate = date(3_000)
        editor.memo = "New memo"

        await store.saveEditor()

        let saved = try #require(await recurringTransactionRepository.savedRecurringTransactions().last)
        #expect(saved.id == recurringTransaction.id)
        #expect(saved.accountID == newAccount.id)
        #expect(saved.direction == .inflow)
        #expect(saved.amount == (try Money(amount: try decimal("123.456"), currencyCode: "EUR")))
        #expect(saved.frequency == .yearly)
        #expect(saved.startDate == date(2_000))
        #expect(saved.endDate == date(3_000))
        #expect(saved.memo == "New memo")
    }

    @Test func editCanChangeEndDateFromNonNilToNilAndClearMemo() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(
            accountID: account.id,
            endDate: date(2_000),
            memo: "Memo"
        )
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository(
            recurringTransactions: [recurringTransaction]
        )
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.startEditing(recurringTransaction)
        let editor = try #require(store.editor)
        editor.hasEndDate = false
        editor.memo = "  "

        await store.saveEditor()

        let saved = try #require(await recurringTransactionRepository.savedRecurringTransactions().last)
        #expect(saved.id == recurringTransaction.id)
        #expect(saved.endDate == nil)
        #expect(saved.memo == nil)
    }

    @Test func failedEditSaveSurfaces() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(accountID: account.id)
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [recurringTransaction],
                saveError: RecurringTransactionsFeatureError.saveFailed
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.startEditing(recurringTransaction)

        await store.saveEditor()

        #expect(store.editor?.errorMessage != nil)
    }

    @Test func confirmedDeleteInvokesRepositoryAndClearsPendingDeletion() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(accountID: account.id)
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository(
            recurringTransactions: [recurringTransaction]
        )
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.requestDelete(recurringTransaction)

        await store.confirmDelete(recurringTransaction)

        #expect(await recurringTransactionRepository.deletedRecurringTransactionIDs() == [recurringTransaction.id])
        #expect(store.pendingDeletion == nil)
    }

    @Test func cancellationDoesNotDelete() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(accountID: account.id)
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository(
            recurringTransactions: [recurringTransaction]
        )
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()
        store.requestDelete(recurringTransaction)
        store.cancelDelete()

        #expect(store.pendingDeletion == nil)
        #expect(await recurringTransactionRepository.deletedRecurringTransactionIDs() == [])
    }

    @Test func deleteFailureSurfaces() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(accountID: account.id)
        let recurringTransactionRepository = RecurringTransactionsFeatureRepository(
            recurringTransactions: [recurringTransaction],
            deleteError: RecurringTransactionsFeatureError.deleteFailed
        )
        let store = makeStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account])
        )

        await store.loadRecurringTransactions()

        await store.confirmDelete(recurringTransaction)

        #expect(store.errorMessage != nil)
        #expect(await recurringTransactionRepository.deletedRecurringTransactionIDs() == [recurringTransaction.id])
    }

    @Test func endedRecurringTransactionShowsNoNextOccurrence() async throws {
        let account = try makeAccount()
        let recurringTransaction = try makeRecurringTransaction(
            accountID: account.id,
            frequency: .daily,
            startDate: utcDate(year: 2026, month: 1, day: 1),
            endDate: utcDate(year: 2026, month: 1, day: 2)
        )
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [recurringTransaction]
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account]),
            referenceDate: { utcDate(year: 2026, month: 1, day: 10) }
        )

        await store.loadRecurringTransactions()

        #expect(store.nextOccurrence(for: recurringTransaction.id) == nil)
    }

    @Test func detailRouteExposesDomainDataAndDerivedNextOccurrence() async throws {
        let account = try makeAccount(name: "Everyday")
        let recurringTransaction = try makeRecurringTransaction(
            accountID: account.id,
            frequency: .daily,
            startDate: utcDate(year: 2026, month: 1, day: 1)
        )
        let store = makeStore(
            recurringTransactionRepository: RecurringTransactionsFeatureRepository(
                recurringTransactions: [recurringTransaction]
            ),
            accountRepository: RecurringTransactionsFeatureAccountRepository(accounts: [account]),
            referenceDate: { utcDate(year: 2026, month: 1, day: 1) }
        )

        await store.loadRecurringTransactions()
        store.selectDetail(recurringTransactionID: recurringTransaction.id)

        #expect(store.route == .detail(recurringTransaction.id))
        #expect(store.recurringTransaction(id: recurringTransaction.id) == recurringTransaction)
        #expect(store.accountName(for: recurringTransaction.accountID) == "Everyday")
        #expect(store.nextOccurrence(for: recurringTransaction.id) == utcDate(year: 2026, month: 1, day: 2))
    }

    private func makeStore(
        recurringTransactionRepository: RecurringTransactionsFeatureRepository = RecurringTransactionsFeatureRepository(),
        accountRepository: RecurringTransactionsFeatureAccountRepository = RecurringTransactionsFeatureAccountRepository(),
        nextOccurrenceProvider: @escaping RecurringTransactionNextOccurrenceProvider = { recurringTransaction, calendar, referenceDate in
            try RecurringTransactionSchedule(
                recurringTransaction: recurringTransaction,
                calendar: calendar
            ).nextOccurrence(after: referenceDate)
        },
        referenceDate: @escaping @MainActor @Sendable () -> Date = { date(1_500) },
        locale: Locale = Locale(identifier: "en_GB")
    ) -> RecurringTransactionsStore {
        RecurringTransactionsStore(
            recurringTransactionRepository: recurringTransactionRepository,
            accountRepository: accountRepository,
            calendar: Self.fixedCalendar,
            nextOccurrenceProvider: nextOccurrenceProvider,
            referenceDate: referenceDate,
            locale: locale
        )
    }

    private static var fixedCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }
}

private final class RecurringTransactionsFeatureNextOccurrenceProvider: @unchecked Sendable {
    struct Request: Equatable {
        let recurringTransactionID: RecurringTransactionID
        let referenceDate: Date
    }

    private(set) var requests: [Request] = []
    private let error: Error?

    init(error: Error? = nil) {
        self.error = error
    }

    func provider(
        recurringTransaction: RecurringTransaction,
        calendar: Calendar,
        referenceDate: Date
    ) throws -> Date? {
        requests.append(Request(
            recurringTransactionID: recurringTransaction.id,
            referenceDate: referenceDate
        ))

        if let error {
            throw error
        }

        return try RecurringTransactionSchedule(
            recurringTransaction: recurringTransaction,
            calendar: calendar
        ).nextOccurrence(after: referenceDate)
    }
}

private actor RecurringTransactionsFeatureRepository: RecurringTransactionRepository {
    private var recurringTransactions: [RecurringTransaction]
    private var saved: [RecurringTransaction] = []
    private var deletedIDs: [RecurringTransactionID] = []
    private let fetchError: Error?
    private let saveError: Error?
    private let deleteError: Error?

    init(
        recurringTransactions: [RecurringTransaction] = [],
        fetchError: Error? = nil,
        saveError: Error? = nil,
        deleteError: Error? = nil
    ) {
        self.recurringTransactions = recurringTransactions
        self.fetchError = fetchError
        self.saveError = saveError
        self.deleteError = deleteError
    }

    func fetchRecurringTransactions() async throws -> [RecurringTransaction] {
        if let fetchError {
            throw fetchError
        }

        return recurringTransactions
    }

    func fetchRecurringTransaction(id: RecurringTransactionID) async throws -> RecurringTransaction? {
        recurringTransactions.first { $0.id == id }
    }

    func save(_ recurringTransaction: RecurringTransaction) async throws {
        if let saveError {
            throw saveError
        }

        saved.append(recurringTransaction)

        if let index = recurringTransactions.firstIndex(where: { $0.id == recurringTransaction.id }) {
            recurringTransactions[index] = recurringTransaction
        } else {
            recurringTransactions.append(recurringTransaction)
        }
    }

    func deleteRecurringTransaction(id: RecurringTransactionID) async throws {
        deletedIDs.append(id)

        if let deleteError {
            throw deleteError
        }

        recurringTransactions.removeAll { $0.id == id }
    }

    func savedRecurringTransactions() async -> [RecurringTransaction] {
        saved
    }

    func deletedRecurringTransactionIDs() async -> [RecurringTransactionID] {
        deletedIDs
    }
}

private actor RecurringTransactionsFeatureAccountRepository: AccountRepository {
    private let accounts: [Account]
    private let fetchError: Error?

    init(accounts: [Account] = [], fetchError: Error? = nil) {
        self.accounts = accounts
        self.fetchError = fetchError
    }

    func fetchAccounts() async throws -> [Account] {
        if let fetchError {
            throw fetchError
        }

        return accounts
    }

    func fetchAccount(id: AccountID) async throws -> Account? {
        accounts.first { $0.id == id }
    }

    func save(_ account: Account) async throws {}

    func deleteAccount(id: AccountID) async throws {}
}

private enum RecurringTransactionsFeatureError: Error {
    case fetchFailed
    case saveFailed
    case deleteFailed
    case scheduleFailed
}

private func makeAccount(
    name: String = "Everyday",
    currencyCode: String = "GBP"
) throws -> Account {
    try Account(
        name: name,
        type: .checking,
        currencyCode: currencyCode,
        openingBalance: Money(amount: 0, currencyCode: currencyCode)
    )
}

private func makeRecurringTransaction(
    accountID: AccountID = AccountID(),
    direction: TransactionDirection = .outflow,
    amount: Money? = nil,
    frequency: RecurrenceFrequency = .monthly,
    startDate: Date = date(1_000),
    endDate: Date? = nil,
    memo: String? = nil
) throws -> RecurringTransaction {
    try RecurringTransaction(
        accountID: accountID,
        direction: direction,
        amount: amount ?? Money(amount: 10, currencyCode: "GBP"),
        frequency: frequency,
        startDate: startDate,
        endDate: endDate,
        memo: memo
    )
}

private func date(_ interval: TimeInterval) -> Date {
    Date(timeIntervalSince1970: interval)
}

private func utcDate(year: Int, month: Int, day: Int) -> Date {
    var components = DateComponents()
    components.calendar = {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        return calendar
    }()
    components.timeZone = TimeZone(secondsFromGMT: 0)!
    components.year = year
    components.month = month
    components.day = day

    return components.date!
}

private func decimal(_ value: String) throws -> Decimal {
    try #require(Decimal(string: value, locale: Locale(identifier: "en_US_POSIX")))
}
