# 10 Budget Domain

Status: completed

## Objective

Create the `Budget` domain model for category-based spending limits over validated date periods.

## Scope

- Add `BudgetID`, `BudgetPeriod`, and `Budget`.
- Link budgets to `CategoryID`.
- Store a non-negative `Money` limit.
- Validate period start and end dates.

## Constraints

- Do not implement persistence or repository behavior.
- Do not add spent amount, progress, rollover, recurrence, alerts, account linkage, timestamps, or metadata.
- Keep domain types independent of SwiftData.

## Required Files or Areas

- `App/Cairn/Core/Finance/Budget.swift`
- `App/CairnTests/Core/Finance/BudgetTests.swift`

## Key Design Decisions

- `BudgetPeriod` requires `endDate > startDate`.
- Budget limits must be zero or positive.
- Codable reconstruction goes through validated initializers.

## Validation Requirements

- Tests cover ID codability, period validation, limit validation, Codable invariant enforcement, equality/hashability, and Sendable.

## Review Focus

- BudgetPeriod invariant preservation.
- Negative-limit rejection.
- Scope restraint around future budget features.

## Commit Intent

Commit the budget domain model and tests.
