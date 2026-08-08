# Milestone 32: Goal Progress Calculation

Status: completed

## Objective

Implement the authoritative derived progress calculation for a `Goal`.

Goal progress must be calculated from an existing valid `Goal` domain value without persisting derived state. The derived result should report the original goal, exact remaining amount, completion state, and a deterministic Decimal progress ratio.

## Scope

- Add a focused pure finance calculator for deriving progress for one goal.
- Calculate `remainingAmount = targetAmount - currentAmount` using `Money` arithmetic.
- Calculate `isCompleted` from `currentAmount == targetAmount`.
- Return a small immutable derived value containing `goal`, `remainingAmount`, `isCompleted`, and `progressRatio`.
- Define zero-target progress deterministically as completed progress.
- Add focused domain/application tests for remaining amount, completion, target-date independence, currency preservation, immutability, and Decimal ratio behavior.
- Update this milestone spec and the prompt README.

## Constraints

- Do not persist, cache, or store derived progress state.
- Do not modify `Goal` to cache a percentage or derived progress.
- Do not add UI formatting, percentage strings, presentation state, or SwiftUI views.
- Do not duplicate `Goal` validation.
- Do not depend on `GoalRepository` unless inspection reveals a genuine need.
- Do not import SwiftData or SwiftUI.
- Do not use `Double` or `Float`.
- Do not create `NaN` or infinity output.
- Do not clamp values unless existing `Goal` invariants already guarantee the range.
- Do not use `targetDate` to determine completion.
- Do not introduce overdue, on-track, projected completion, daily savings requirement, milestone status, contributions, recurring contributions, account linkage, projections, alerts, milestone tracking, generic calculation frameworks, service locators, or singleton APIs.

## Affected Files

- `App/Cairn/Core/Finance/CalculateGoalProgress.swift`
- `App/CairnTests/Core/Finance/CalculateGoalProgressTests.swift`
- `Documentation/prompts/32-goal-progress.md`
- `Documentation/prompts/README.md`

## Key Design Decisions

- Place the calculator in `Core/Finance` because it composes shared finance domain types and is expected to become the authoritative calculation later used by Goals UI and Dashboard.
- Prefer a pure calculation over orchestration; the calculator accepts an existing `Goal` and does not fetch repositories.
- Return a `GoalProgress` value type with immutable stored properties.
- Reuse `Money.subtracting(_:)` for remaining amount so currency checks stay inside `Money`.
- Let `Money` errors propagate from subtraction rather than adding a new application error.
- Calculate completion solely from exact `Money` equality between current and target amounts.
- Ignore `targetDate` for completion because it is scheduling/context metadata.
- Include `progressRatio` as a `Decimal`, calculated as `currentAmount.amount / targetAmount.amount` when the target is positive.
- Define the valid zero-target/zero-current case as `progressRatio == 1` and `isCompleted == true`.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run `CalculateGoalProgressTests` on a concrete available iPhone simulator.
- Run `GoalTests`.
- Run `MoneyTests`.
- Run `/review` focused on the review areas below.
- Show `git status --short`.
- Show the complete relevant diff.

## Review Focus

- Remaining amount correctness.
- Completion semantics.
- Zero-target semantics.
- Decimal correctness.
- No duplicated `Goal` validation.
- No repository or persistence dependency.
- No SwiftData or UI leakage.
- Unnecessary abstraction.
- Suitability for Goals UI and Dashboard.

## Commit Intent

Commit the goal-progress calculator, focused tests, completed milestone documentation, and prompt README update.
