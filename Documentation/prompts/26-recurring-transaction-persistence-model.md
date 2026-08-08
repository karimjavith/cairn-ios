# Milestone 26: Recurring Transaction Persistence Model

Status: completed

## Objective

Implement the SwiftData persistence model and mapping boundary for `RecurringTransaction`.

## Scope

- Add `RecurringTransactionRecord` as the SwiftData `@Model` for recurring transactions.
- Persist only the primitive values required to reconstruct a `RecurringTransaction`.
- Add explicit mapping from `RecurringTransaction` to `RecurringTransactionRecord`.
- Add explicit mapping from `RecurringTransactionRecord` to `RecurringTransaction`.
- Register `RecurringTransactionRecord` in the existing centralized SwiftData schema.
- Add focused persistence mapping tests, including one in-memory SwiftData round trip.

## Constraints

- Do not implement `RecurringTransactionRepository`.
- Do not change `RecurringTransaction` domain semantics.
- Do not add relationships to `AccountRecord`.
- Do not persist generated transactions, next-run date, recurrence exceptions, category linkage, transfer metadata, notifications, timestamps, or metadata not present in the domain.
- Preserve `RecurringTransactionID` and `AccountID` exactly across persistence round trips.
- Persist `Money` as exact Decimal string plus currency code, not as `Money`, `Double`, or `Float`.
- Reject malformed persisted Decimal values with full-string parsing.
- Reject invalid persisted direction and recurrence frequency values explicitly.
- Reconstruct through `Money` and `RecurringTransaction` validated initializers.
- Keep domain types SwiftData-independent and persistence-independent.
- Do not introduce generic mapper protocols, DTO layers, persistence frameworks, service locators, or singleton APIs.
- No SwiftUI changes.

## Affected Files

- `Documentation/prompts/26-recurring-transaction-persistence-model.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Persistence/RecurringTransactions/RecurringTransactionRecord.swift`
- `App/CairnTests/Persistence/RecurringTransactions/RecurringTransactionRecordTests.swift`
- `App/Cairn/App/CairnApp.swift`

## Key Design Decisions

- Store `RecurringTransactionID` and `AccountID` as UUID primitives.
- Store `TransactionDirection` as stable strings: `inflow` and `outflow`.
- Store `RecurrenceFrequency` as stable strings: `daily`, `weekly`, `monthly`, and `yearly`.
- Store Decimal amounts using the established strict persistence string pattern.
- Parse persisted Decimal strings with a fixed dot-decimal `en_US_POSIX` locale so reconstruction is independent of the user's current locale.
- Keep mapping errors small and persistence-specific for malformed persisted Decimal, direction, and frequency values.
- Let existing `Money` and `RecurringTransaction` validation errors propagate naturally.
- Use the existing centralized `ModelContainer` schema instead of creating another production container.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `RecurringTransactionRecordTests` on a concrete available iPhone simulator
- Existing `RecurringTransaction` domain tests
- `/review`

## Review Focus

- SwiftData iOS 17 compatibility
- Identifier preservation
- Strict Decimal persistence
- Direction persistence stability
- Recurrence-frequency persistence stability
- Start/end date invariant preservation
- Memo fidelity
- Schema registration
- Mapping error design
- Persistence/domain leakage
- Unnecessary abstraction
- Suitability for future actor-backed `RecurringTransactionRepository`

## Commit Intent

One scoped commit adding the recurring transaction SwiftData record, mapping tests, centralized schema registration, and milestone documentation without staging or committing during implementation.
