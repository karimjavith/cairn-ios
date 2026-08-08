# 11 Goal Domain

Status: completed

## Objective

Create the `Goal` domain model for savings or financial targets.

## Scope

- Add `GoalID` and `Goal`.
- Store name, target amount, current amount, and optional target date.
- Validate name, amounts, currency consistency, and progress bounds.

## Constraints

- Do not implement persistence or repository behavior.
- Do not add presentation progress calculations unless required by domain invariants.
- Keep the model SwiftUI- and SwiftData-independent.

## Required Files or Areas

- `App/Cairn/Core/Finance/Goal.swift`
- `App/CairnTests/Core/Finance/GoalTests.swift`

## Key Design Decisions

- Target and current amounts must be non-negative.
- Current amount cannot exceed target amount.
- Target and current amounts must use the same currency.

## Validation Requirements

- Tests cover successful initialization, validation failures, Codable invariant enforcement, equality/hashability, and Sendable.

## Review Focus

- Financial correctness.
- Currency consistency.
- Avoidance of UI-derived state.

## Commit Intent

Commit the goal domain model and tests.
