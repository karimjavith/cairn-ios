# 21 Budget Persistence Model

Status: completed

## Objective

Create the SwiftData persistence model and mapping boundary for `Budget` only.

## Scope

- Add `BudgetRecord` as a SwiftData `@Model`.
- Persist only values required to reconstruct `Budget`.
- Add explicit mapping between `Budget` and `BudgetRecord`.
- Register the record in the centralized schema.

## Constraints

- Do not implement `BudgetRepository`.
- Do not persist `Money` directly.
- Preserve `BudgetID` and `CategoryID`.
- Do not add spent amount, progress, rollover, recurrence, account linkage, alerts, timestamps, or metadata.
- Keep domain independent of SwiftData.

## Required Files or Areas

- `App/Cairn/Persistence/Budgets/BudgetRecord.swift`
- `App/CairnTests/Persistence/Budgets/BudgetRecordTests.swift`
- `App/Cairn/App/CairnApp.swift`

## Key Design Decisions

- IDs persist as `UUID`.
- Limit amount persists as a strict full-string Decimal representation in text form.
- Currency code persists separately.
- Period start and end dates persist explicitly.
- Mapping back reconstructs through `Money`, `BudgetPeriod`, and `Budget` validation.
- Invalid persisted decimal text fails with `BudgetRecordMappingError.invalidLimitAmount`.

## Validation Requirements

- Tests cover mapping in both directions, ID preservation, high-precision Decimal round trips, currency, dates, zero limit, malformed decimal rejection, negative limit domain validation, invalid period validation, and in-memory SwiftData round trip.
- Generic iOS Simulator build passes.
- `BudgetRecordTests` and existing `BudgetTests` pass on a concrete simulator when simulator execution is healthy.

## Review Focus

- SwiftData iOS 17 compatibility.
- Strict full-string Decimal parsing and precision preservation.
- BudgetID and CategoryID preservation.
- BudgetPeriod invariant preservation.
- Small mapping error design.
- No persistence/domain leakage or unnecessary abstraction.

## Commit Intent

Commit Budget SwiftData record, mapping tests, and schema registration without implementing the repository.
