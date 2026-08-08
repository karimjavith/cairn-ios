//
//  RecurringTransactionScheduleTests.swift
//  CairnTests
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import Testing
@testable import Cairn

struct RecurringTransactionScheduleTests {

    @Test func dailyReferenceBeforeStartReturnsStartDate() throws {
        let calendar = utcCalendar()
        let startDate = try date(2026, 1, 10, 9, 30, calendar: calendar)
        let recurringTransaction = try makeRecurringTransaction(frequency: .daily, startDate: startDate)
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 1, 9, 30, calendar: calendar))

        #expect(occurrence == startDate)
    }

    @Test func dailyReferenceExactlyAtStartReturnsNextDay() throws {
        let calendar = utcCalendar()
        let startDate = try date(2026, 1, 10, 9, 30, calendar: calendar)
        let recurringTransaction = try makeRecurringTransaction(frequency: .daily, startDate: startDate)
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: startDate)
        let expected = try date(2026, 1, 11, 9, 30, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func dailyReferenceBetweenOccurrencesReturnsNextOccurrence() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 10, 9, 30, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 12, 12, 0, calendar: calendar))
        let expected = try date(2026, 1, 13, 9, 30, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func dailyOccurrencesInBoundedRangeAreAscending() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 10, 9, 30, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(
            in: try date(2026, 1, 11, 0, 0, calendar: calendar)..<date(2026, 1, 14, 0, 0, calendar: calendar)
        )
        let expected = [
            try date(2026, 1, 11, 9, 30, calendar: calendar),
            try date(2026, 1, 12, 9, 30, calendar: calendar),
            try date(2026, 1, 13, 9, 30, calendar: calendar)
        ]

        #expect(occurrences == expected)
    }

    @Test func weeklyAdvancesByCalendarWeek() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .weekly,
            startDate: try date(2026, 1, 5, 8, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 12, 8, 0, calendar: calendar))
        let expected = try date(2026, 1, 19, 8, 0, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func weeklyRangeUsesInclusiveStartAndExclusiveEnd() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .weekly,
            startDate: try date(2026, 1, 5, 8, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(
            in: try date(2026, 1, 12, 8, 0, calendar: calendar)..<date(2026, 1, 26, 8, 0, calendar: calendar)
        )
        let expected = [
            try date(2026, 1, 12, 8, 0, calendar: calendar),
            try date(2026, 1, 19, 8, 0, calendar: calendar)
        ]

        #expect(occurrences == expected)
    }

    @Test func monthlyOrdinaryRecurrenceAdvancesByMonth() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .monthly,
            startDate: try date(2026, 1, 15, 14, 45, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 15, 14, 45, calendar: calendar))
        let expected = try date(2026, 2, 15, 14, 45, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func monthlyJanuaryThirtyFirstClampsToFebruaryLastDay() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .monthly,
            startDate: try date(2026, 1, 31, 10, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 31, 10, 0, calendar: calendar))
        let expected = try date(2026, 2, 28, 10, 0, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func monthlyMonthEndUsesOriginalIntendedDayForSubsequentMonths() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .monthly,
            startDate: try date(2026, 1, 31, 10, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(
            in: try date(2026, 1, 1, 0, 0, calendar: calendar)..<date(2026, 5, 1, 0, 0, calendar: calendar)
        )
        let expected = [
            try date(2026, 1, 31, 10, 0, calendar: calendar),
            try date(2026, 2, 28, 10, 0, calendar: calendar),
            try date(2026, 3, 31, 10, 0, calendar: calendar),
            try date(2026, 4, 30, 10, 0, calendar: calendar)
        ]

        #expect(occurrences == expected)
    }

    @Test func yearlyOrdinaryRecurrenceAdvancesByYear() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .yearly,
            startDate: try date(2026, 6, 15, 7, 15, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 6, 15, 7, 15, calendar: calendar))
        let expected = try date(2027, 6, 15, 7, 15, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func yearlyLeapDayClampsToFebruaryTwentyEighthInNonLeapYear() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .yearly,
            startDate: try date(2020, 2, 29, 12, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2020, 2, 29, 12, 0, calendar: calendar))
        let expected = try date(2021, 2, 28, 12, 0, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func yearlyLeapDayReturnsToFebruaryTwentyNinthInLeapYear() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .yearly,
            startDate: try date(2020, 2, 29, 12, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(
            in: try date(2020, 1, 1, 0, 0, calendar: calendar)..<date(2025, 1, 1, 0, 0, calendar: calendar)
        )
        let expected = [
            try date(2020, 2, 29, 12, 0, calendar: calendar),
            try date(2021, 2, 28, 12, 0, calendar: calendar),
            try date(2022, 2, 28, 12, 0, calendar: calendar),
            try date(2023, 2, 28, 12, 0, calendar: calendar),
            try date(2024, 2, 29, 12, 0, calendar: calendar)
        ]

        #expect(occurrences == expected)
    }

    @Test func occurrenceBeforeEndDateIsAllowed() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 1, 9, 0, calendar: calendar),
            endDate: try date(2026, 1, 3, 9, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 1, 9, 0, calendar: calendar))
        let expected = try date(2026, 1, 2, 9, 0, calendar: calendar)

        #expect(occurrence == expected)
    }

    @Test func occurrenceExactlyEqualToEndDateIsExcluded() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 1, 9, 0, calendar: calendar),
            endDate: try date(2026, 1, 3, 9, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 2, 9, 0, calendar: calendar))

        #expect(occurrence == nil)
    }

    @Test func nextOccurrenceReturnsNilWhenRecurrenceHasEnded() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 1, 9, 0, calendar: calendar),
            endDate: try date(2026, 1, 3, 9, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try schedule.nextOccurrence(after: try date(2026, 1, 3, 9, 0, calendar: calendar))

        #expect(occurrence == nil)
    }

    @Test func rangeDoesNotIncludeDatesBeforeStartDate() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 2, 9, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(
            in: try date(2026, 1, 1, 0, 0, calendar: calendar)..<date(2026, 1, 3, 0, 0, calendar: calendar)
        )
        let expected = [
            try date(2026, 1, 2, 9, 0, calendar: calendar)
        ]

        #expect(occurrences == expected)
    }

    @Test func rangeDoesNotIncludeDatesAtOrAfterConfiguredEndDate() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 1, 9, 0, calendar: calendar),
            endDate: try date(2026, 1, 3, 9, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(
            in: try date(2026, 1, 1, 9, 0, calendar: calendar)..<date(2026, 1, 5, 0, 0, calendar: calendar)
        )
        let expected = [
            try date(2026, 1, 1, 9, 0, calendar: calendar),
            try date(2026, 1, 2, 9, 0, calendar: calendar)
        ]

        #expect(occurrences == expected)
    }

    @Test func emptyBoundedRangeReturnsNoOccurrences() throws {
        let calendar = utcCalendar()
        let boundary = try date(2026, 1, 2, 9, 0, calendar: calendar)
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 1, 9, 0, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrences = try schedule.occurrences(in: boundary..<boundary)

        #expect(occurrences == [])
    }

    @Test func monthlyTimeOfDayIsPreserved() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .monthly,
            startDate: try date(2026, 1, 31, 14, 45, 30, calendar: calendar)
        )
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try #require(try schedule.nextOccurrence(after: recurringTransaction.startDate))
        let components = calendar.dateComponents([.hour, .minute, .second], from: occurrence)

        #expect(components.hour == 14)
        #expect(components.minute == 45)
        #expect(components.second == 30)
    }

    @Test func dailyRecurrenceAcrossDSTPreservesLocalWallClockTime() throws {
        let calendar = londonCalendar()
        let startDate = try date(2026, 3, 28, 9, 0, calendar: calendar)
        let recurringTransaction = try makeRecurringTransaction(frequency: .daily, startDate: startDate)
        let schedule = RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)

        let occurrence = try #require(try schedule.nextOccurrence(after: startDate))
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: occurrence)

        #expect(components.year == 2026)
        #expect(components.month == 3)
        #expect(components.day == 29)
        #expect(components.hour == 9)
        #expect(components.minute == 0)
        #expect(occurrence.timeIntervalSince(startDate) == 82_800)
    }

    @Test func directionAmountAccountAndMemoDoNotAffectScheduling() throws {
        let calendar = utcCalendar()
        let startDate = try date(2026, 1, 10, 9, 0, calendar: calendar)
        let first = try makeRecurringTransaction(
            accountID: AccountID(rawValue: try #require(UUID(uuidString: "11111111-1111-1111-1111-111111111111"))),
            direction: .outflow,
            amount: Money(amount: 25, currencyCode: "GBP"),
            frequency: .weekly,
            startDate: startDate,
            memo: "Rent"
        )
        let second = try makeRecurringTransaction(
            accountID: AccountID(rawValue: try #require(UUID(uuidString: "22222222-2222-2222-2222-222222222222"))),
            direction: .inflow,
            amount: Money(amount: 100, currencyCode: "GBP"),
            frequency: .weekly,
            startDate: startDate,
            memo: "Salary"
        )

        let firstOccurrence = try RecurringTransactionSchedule(
            recurringTransaction: first,
            calendar: calendar
        ).nextOccurrence(after: startDate)
        let secondOccurrence = try RecurringTransactionSchedule(
            recurringTransaction: second,
            calendar: calendar
        ).nextOccurrence(after: startDate)

        #expect(firstOccurrence == secondOccurrence)
    }

    @Test func recurringTransactionScheduleIsSendable() throws {
        let calendar = utcCalendar()
        let recurringTransaction = try makeRecurringTransaction(
            frequency: .daily,
            startDate: try date(2026, 1, 10, 9, 0, calendar: calendar)
        )

        requireSendable(RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar))
    }

    private func makeRecurringTransaction(
        accountID: AccountID? = nil,
        direction: TransactionDirection = .outflow,
        amount: Money? = nil,
        frequency: RecurrenceFrequency,
        startDate: Date,
        endDate: Date? = nil,
        memo: String? = nil
    ) throws -> RecurringTransaction {
        let defaultAccountID = AccountID(rawValue: try #require(UUID(uuidString: "9E849395-8DC9-481A-B56F-1EC9AF46A57D")))

        return try RecurringTransaction(
            accountID: accountID ?? defaultAccountID,
            direction: direction,
            amount: amount ?? Money(amount: 12.34, currencyCode: "GBP"),
            frequency: frequency,
            startDate: startDate,
            endDate: endDate,
            memo: memo
        )
    }

    private func utcCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func londonCalendar() -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/London")!
        calendar.locale = Locale(identifier: "en_US_POSIX")
        return calendar
    }

    private func date(
        _ year: Int,
        _ month: Int,
        _ day: Int,
        _ hour: Int,
        _ minute: Int,
        _ second: Int = 0,
        calendar: Calendar
    ) throws -> Date {
        var components = DateComponents()
        components.calendar = calendar
        components.timeZone = calendar.timeZone
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = second

        return try #require(calendar.date(from: components))
    }

    private func requireSendable<T: Sendable>(_ value: T) {
        _ = value
    }
}
