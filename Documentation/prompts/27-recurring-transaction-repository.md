# Milestone 27: Recurring Transaction Repository

Status: completed

## Objective

Implement the SwiftData-backed `RecurringTransactionRepository`.

## Scope

- Add a concrete `SwiftDataRecurringTransactionRepository` in Persistence.
- Conform to the existing `RecurringTransactionRepository` domain protocol.
- Persist, update, fetch, sort, and delete recurring transactions through `RecurringTransactionRecord`.
- Add focused repository tests using an isolated in-memory SwiftData `ModelContainer`.
- Keep milestone documentation and the prompt index aligned.

## Constraints

- Do not modify `RecurringTransaction` domain semantics.
- Do not weaken `RecurringTransactionRepository` `Sendable`.
- Do not mark the domain repository protocol `MainActor`.
- Do not expose `RecurringTransactionRecord` or `ModelContext` to callers.
- Do not create global `ModelContext` state, additional production `ModelContainer` instances, custom concurrency abstractions, generic repository base classes, cache/sync behavior, or unrelated production changes.
- Use the same proven actor-isolated SwiftData pattern as the existing repositories.
- Use `RecurringTransactionRecord` mapping logic rather than duplicating persistence conversion rules.
- Mapping errors and SwiftData errors must propagate.
- Invalid persisted records must not be silently skipped or defaulted.

## Affected Files

- `Documentation/prompts/27-recurring-transaction-repository.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Persistence/RecurringTransactions/SwiftDataRecurringTransactionRepository.swift`
- `App/CairnTests/Persistence/RecurringTransactions/SwiftDataRecurringTransactionRepositoryTests.swift`

## Key Design Decisions

- Implement the repository as an `@ModelActor` actor to match existing SwiftData repositories.
- Fetch by raw `RecurringTransactionID` UUID with `includePendingChanges` and a fetch limit of one.
- Save by updating an existing record when the ID already exists, otherwise inserting a new record.
- Reuse `RecurringTransactionRecord(recurringTransaction:)` inside record update logic so persistence conversion remains centralized in the record mapping.
- Fetch all records without SwiftData optional sort descriptors, map every record, then sort domain values in repository memory for deterministic iOS 17-compatible ordering.
- Order by `startDate` ascending, then non-nil `endDate` before nil, then non-nil `endDate` ascending, then `RecurringTransactionID` UUID string.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `SwiftDataRecurringTransactionRepositoryTests` on a concrete available iPhone simulator
- Existing `RecurringTransactionRecordTests`
- Existing `RecurringTransaction` domain tests
- `/review`

## Review Focus

- `@ModelActor` and `ModelContext` correctness
- `Sendable` conformance
- iOS 17 SwiftData compatibility
- Deterministic optional `endDate` ordering
- Update-vs-insert behavior
- Duplicate prevention
- `AccountID` updates
- Direction and frequency fidelity
- Decimal precision
- Date and memo fidelity
- Error propagation
- Persistence/domain leakage
- Unnecessary abstraction
- Consistency with existing repository implementations

## Commit Intent

One scoped commit adding the SwiftData recurring transaction repository, repository tests, and milestone documentation updates without staging or committing during implementation.
