//
//  RecurringTransactionSchedule.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation

nonisolated struct RecurringTransactionSchedule: Sendable {
    let recurringTransaction: RecurringTransaction
    let calendar: Calendar

    init(recurringTransaction: RecurringTransaction, calendar: Calendar) {
        self.recurringTransaction = recurringTransaction
        self.calendar = calendar
    }

    func nextOccurrence(after referenceDate: Date) throws -> Date? {
        guard let occurrence = try firstOccurrence(onOrAfter: referenceDate, includingReferenceDate: false) else {
            return nil
        }

        return isBeforeEndDate(occurrence) ? occurrence : nil
    }

    func occurrences(in range: Range<Date>) throws -> [Date] {
        guard range.lowerBound < range.upperBound,
              var occurrence = try firstOccurrence(onOrAfter: range.lowerBound, includingReferenceDate: true) else {
            return []
        }

        var occurrences: [Date] = []

        while occurrence < range.upperBound, isBeforeEndDate(occurrence) {
            occurrences.append(occurrence)

            guard let nextOccurrence = try nextOccurrence(after: occurrence) else {
                return occurrences
            }

            occurrence = nextOccurrence
        }

        return occurrences
    }

    private func firstOccurrence(
        onOrAfter referenceDate: Date,
        includingReferenceDate: Bool
    ) throws -> Date? {
        let startDate = recurringTransaction.startDate

        if referenceDate < startDate || (includingReferenceDate && referenceDate == startDate) {
            return isBeforeEndDate(startDate) ? startDate : nil
        }

        var index = try occurrenceIndexEstimate(for: referenceDate)
        var occurrence = try occurrence(at: index)

        while occurrence < referenceDate || (!includingReferenceDate && occurrence == referenceDate) {
            index += 1
            occurrence = try self.occurrence(at: index)
        }

        while index > 0 {
            let previousOccurrence = try self.occurrence(at: index - 1)

            guard previousOccurrence >= referenceDate,
                  includingReferenceDate || previousOccurrence != referenceDate else {
                break
            }

            index -= 1
            occurrence = previousOccurrence
        }

        return isBeforeEndDate(occurrence) ? occurrence : nil
    }

    private func occurrenceIndexEstimate(for referenceDate: Date) throws -> Int {
        let component: Calendar.Component

        switch recurringTransaction.frequency {
        case .daily:
            component = .day
        case .weekly:
            component = .weekOfYear
        case .monthly:
            component = .month
        case .yearly:
            component = .year
        }

        guard let value = calendar.dateComponents(
            [component],
            from: recurringTransaction.startDate,
            to: referenceDate
        ).value(for: component) else {
            throw RecurringTransactionScheduleError.calendarCalculationFailed
        }

        return max(0, value)
    }

    private func occurrence(at index: Int) throws -> Date {
        switch recurringTransaction.frequency {
        case .daily:
            return try occurrence(byAdding: .day, value: index)
        case .weekly:
            return try occurrence(byAdding: .weekOfYear, value: index)
        case .monthly:
            return try occurrenceByAddingMonths(index)
        case .yearly:
            return try occurrenceByAddingYears(index)
        }
    }

    private func occurrence(byAdding component: Calendar.Component, value: Int) throws -> Date {
        guard let occurrence = calendar.date(
            byAdding: component,
            value: value,
            to: recurringTransaction.startDate
        ) else {
            throw RecurringTransactionScheduleError.calendarCalculationFailed
        }

        return occurrence
    }

    private func occurrenceByAddingMonths(_ months: Int) throws -> Date {
        try occurrenceByAdding(months: months, years: 0)
    }

    private func occurrenceByAddingYears(_ years: Int) throws -> Date {
        try occurrenceByAdding(months: 0, years: years)
    }

    private func occurrenceByAdding(months: Int, years: Int) throws -> Date {
        let originalComponents = calendar.dateComponents(
            [.era, .year, .month, .day, .hour, .minute, .second, .nanosecond],
            from: recurringTransaction.startDate
        )

        guard let originalYear = originalComponents.year,
              let originalMonth = originalComponents.month,
              let originalDay = originalComponents.day else {
            throw RecurringTransactionScheduleError.calendarCalculationFailed
        }

        var sourceComponents = DateComponents()
        sourceComponents.calendar = calendar
        sourceComponents.timeZone = calendar.timeZone
        sourceComponents.era = originalComponents.era
        sourceComponents.year = originalYear
        sourceComponents.month = originalMonth
        sourceComponents.day = 1
        sourceComponents.hour = originalComponents.hour
        sourceComponents.minute = originalComponents.minute
        sourceComponents.second = originalComponents.second
        sourceComponents.nanosecond = originalComponents.nanosecond

        guard let sourceDate = calendar.date(from: sourceComponents),
              let targetMonth = calendar.date(
                byAdding: DateComponents(year: years, month: months),
                to: sourceDate
              ),
              let validDays = calendar.range(of: .day, in: .month, for: targetMonth) else {
            throw RecurringTransactionScheduleError.calendarCalculationFailed
        }

        let targetComponents = calendar.dateComponents([.era, .year, .month], from: targetMonth)
        var occurrenceComponents = DateComponents()
        occurrenceComponents.calendar = calendar
        occurrenceComponents.timeZone = calendar.timeZone
        occurrenceComponents.era = targetComponents.era
        occurrenceComponents.year = targetComponents.year
        occurrenceComponents.month = targetComponents.month
        occurrenceComponents.day = min(originalDay, validDays.count)
        occurrenceComponents.hour = originalComponents.hour
        occurrenceComponents.minute = originalComponents.minute
        occurrenceComponents.second = originalComponents.second
        occurrenceComponents.nanosecond = originalComponents.nanosecond

        guard let occurrence = calendar.date(from: occurrenceComponents) else {
            throw RecurringTransactionScheduleError.calendarCalculationFailed
        }

        return occurrence
    }

    private func isBeforeEndDate(_ occurrence: Date) -> Bool {
        guard let endDate = recurringTransaction.endDate else {
            return true
        }

        return occurrence < endDate
    }
}

nonisolated enum RecurringTransactionScheduleError: Error, Equatable, Sendable {
    case calendarCalculationFailed
}
