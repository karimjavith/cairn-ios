# Milestone 23: SwiftData Budget Repository

Status: completed

## Objective

Implement the SwiftData-backed `BudgetRepository` concrete adapter for persisted budgets.

## Scope

- Add `SwiftDataBudgetRepository` in Persistence.
- Conform to the existing `BudgetRepository` protocol.
- Persist and fetch only `Budget` domain values through `BudgetRecord`.
- Add focused repository tests using an isolated in-memory SwiftData `ModelContainer`.

## Constraints

- Do not modify unrelated production files.
- Do not change `BudgetRepository`, `Budget`, `BudgetRecord`, or centralized schema behavior.
- Do not expose `BudgetRecord` or `ModelContext` to repository callers.
- Do not weaken `BudgetRepository` `Sendable` conformance.
- Do not mark the domain protocol `MainActor`.
- Do not use global `ModelContext`, create extra `ModelContainer` instances in production, or introduce custom concurrency abstractions.
- Do not add budget progress, spent amount, rollover, recurrence, date-range queries, category-specific fetches, pagination, search, generic repository base classes, cache/sync behavior, or batch APIs.

## Affected Files

- `Documentation/prompts/23-budget-repository.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Persistence/Budgets/SwiftDataBudgetRepository.swift`
- `App/CairnTests/Persistence/Budgets/SwiftDataBudgetRepositoryTests.swift`

## Key Design Decisions

- Use the same `@ModelActor` SwiftData repository pattern as the existing Account, Transaction, and Category repositories.
- Fetch all budgets with deterministic SwiftData sorting: period start date descending, period end date descending, and budget ID ascending as the stable tertiary key.
- Fetch single budgets by persisted `BudgetID` with `includePendingChanges` and a fetch limit of one.
- Save updates existing records for the same `BudgetID`; otherwise insert a new `BudgetRecord`.
- Existing records are updated by applying values from `BudgetRecord(budget:)` so persistence conversion rules remain centralized in the record mapping.
- Delete treats a missing ID as a successful no-op.
- Mapping and SwiftData errors propagate unchanged.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `SwiftDataBudgetRepositoryTests` on a concrete simulator
- Existing `BudgetRecordTests`
- Existing Budget domain tests
- `/review`

## Review Focus

- `@ModelActor` / `ModelContext` correctness
- `Sendable` conformance
- Deterministic ordering
- Update-vs-insert behavior
- Duplicate prevention
- `CategoryID` updates
- Decimal precision
- `BudgetPeriod` fidelity
- Error propagation
- Persistence/domain leakage
- Unnecessary abstraction
- Suitability as the reference pattern for Goal and RecurringTransaction repositories

## Commit Intent

One scoped commit adding the SwiftData Budget repository, focused persistence tests, and milestone documentation without staging or committing during implementation.
