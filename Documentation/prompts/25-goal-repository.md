# Milestone 25: Goal Repository

Status: completed

## Objective

Implement the SwiftData-backed `GoalRepository` concrete repository only.

## Scope

- Add `SwiftDataGoalRepository` in Persistence.
- Conform to the existing `GoalRepository` domain protocol.
- Persist inserts, updates, fetches, and deletes through the existing `GoalRecord` model.
- Return only `Goal` domain values from repository reads.
- Add focused in-memory SwiftData tests for repository behavior, ordering, updates, deletion, fidelity, and mapping errors.

## Constraints

- Do not change `Goal`, `GoalRepository`, `GoalRecord`, or domain semantics.
- Do not weaken `GoalRepository` `Sendable`.
- Do not mark the domain protocol `MainActor`.
- Do not expose `GoalRecord` or `ModelContext` to callers.
- Do not create another production `ModelContainer`.
- Do not introduce service locators, singletons, custom concurrency abstractions, generic repository base classes, cache/sync behavior, batch APIs, search, pagination, contribution history, account linkage, recurring contributions, or goal progress calculations.
- Preserve the domain/persistence boundary and reconstruct reads through `GoalRecord.goal()`.

## Affected Files

- `Documentation/prompts/25-goal-repository.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Persistence/Goals/SwiftDataGoalRepository.swift`
- `App/CairnTests/Persistence/Goals/SwiftDataGoalRepositoryTests.swift`

## Key Design Decisions

- Use the same `@ModelActor` SwiftData repository pattern as the existing Account, Transaction, Category, and Budget repositories.
- Use the repository actor's injected `ModelContainer` and synthesized `modelContext`; callers never receive or provide a `ModelContext`.
- Fetch records with `includePendingChanges = true` for consistency with existing repositories.
- Fetch all `GoalRecord` values without relying on optional-date SwiftData sorting, then apply deterministic ordering in the repository for iOS 17 compatibility.
- Order goals by non-`nil` `targetDate` before `nil`, `targetDate` ascending, `name` ascending when target dates are equal, and `GoalID.rawValue.uuidString` ascending as the stable final ordering.
- Save by fetching the existing record for the `GoalID`; update it through `GoalRecord(goal:)` mapped values or insert a new `GoalRecord`.
- Delete missing `GoalID` values as successful no-ops.
- Let SwiftData errors and mapping/domain validation errors propagate unchanged.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `SwiftDataGoalRepositoryTests` on a concrete available iPhone simulator
- Existing `GoalRecordTests`
- Existing Goal domain tests
- `/review`

## Review Focus

- `@ModelActor` and `ModelContext` correctness
- `Sendable` conformance
- iOS 17 SwiftData compatibility
- Optional `targetDate` ordering
- Deterministic secondary and tertiary ordering
- Update-vs-insert behavior
- Duplicate prevention
- Decimal precision
- `targetDate` fidelity
- Error propagation
- Persistence/domain leakage
- Unnecessary abstraction
- Consistency with existing repository implementations

## Commit Intent

One scoped commit adding the SwiftData-backed `GoalRepository`, repository tests, and milestone documentation without staging or committing during implementation.
