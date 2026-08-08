# Milestone 24: Goal Persistence Model

Status: completed

## Objective

Implement the SwiftData persistence model and explicit mapping boundary for `Goal` only.

## Scope

- Add `GoalRecord` as a SwiftData `@Model`.
- Map `Goal` domain values to persisted primitive fields.
- Reconstruct `Goal` domain values from persisted primitive fields.
- Register `GoalRecord` in the centralized application SwiftData schema.
- Add focused record mapping tests and one in-memory SwiftData round-trip test.

## Constraints

- Do not implement `GoalRepository`.
- Do not change `Goal`, `GoalRepository`, `Money`, or existing domain semantics.
- Do not modify SwiftUI views.
- Do not create another production `ModelContainer`.
- Do not persist `Money` directly.
- Do not add progress percentage, contribution history, account linkage, recurring contributions, milestone state, alerts, timestamps, or metadata not present in `Goal`.
- Do not introduce generic mapper protocols, DTO layers, persistence frameworks, service locators, or singleton APIs.
- Keep the `Goal` domain model SwiftData-independent and `ModelContext`-free.

## Affected Files

- `Documentation/prompts/24-goal-persistence-model.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Persistence/Goals/GoalRecord.swift`
- `App/CairnTests/Persistence/Goals/GoalRecordTests.swift`
- `App/Cairn/App/CairnApp.swift`

## Key Design Decisions

- Persist `GoalID` as its raw `UUID` to preserve identity across persistence round trips.
- Store goal names after domain normalization by mapping from an already validated `Goal`.
- Store monetary amounts as strict string representations of `Decimal` values, matching the established persistence pattern.
- Parse persisted monetary strings with a full-string decimal pattern before `Decimal(string:)`.
- Reject malformed persisted decimal strings explicitly with small typed mapping errors.
- Reconstruct through `Money` and then `Goal` so persisted state cannot bypass domain validation.
- Persist `targetDate` directly as an optional `Date`; `nil`, non-`nil`, and past dates all round-trip without additional calendar semantics.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `GoalRecordTests` on a concrete simulator
- Existing Goal domain tests
- `/review`

## Review Focus

- SwiftData iOS 17 compatibility
- `GoalID` preservation
- Strict `Decimal` persistence
- Precision preservation
- Currency invariant preservation
- `Goal` invariant enforcement
- Optional `targetDate` fidelity
- Schema registration
- Error design
- Persistence/domain leakage
- Unnecessary abstraction
- Suitability for future actor-backed `GoalRepository`

## Commit Intent

One scoped commit adding the SwiftData `GoalRecord`, mapping tests, centralized schema registration, and milestone documentation without staging or committing during implementation.
