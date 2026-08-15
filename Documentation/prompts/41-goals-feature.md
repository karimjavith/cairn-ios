# Milestone 41: Goals Feature

Status: completed

## Objective

Replace the Goals placeholder with a functional goal-management feature.

The Goals feature must support:

- goal list
- derived goal progress
- create goal
- edit goal
- delete goal
- goal detail

The feature must reuse the existing `Goal`, `GoalRepository`, and `CalculateGoalProgress` boundaries. It must not persist derived progress values or duplicate goal-domain validation in SwiftUI.

## Existing Context

The goal domain model exists in `App/Cairn/Core/Finance/Goal.swift`.

`Goal` is a validated value type with:

- stable `GoalID`
- trimmed non-empty name
- non-negative target `Money`
- non-negative current `Money`
- matching target/current currency
- current amount not exceeding target amount
- optional target date

`GoalRepository` defines async goal persistence operations:

- `fetchGoals()`
- `fetchGoal(id:)`
- `save(_:)`
- `deleteGoal(id:)`

`SwiftDataGoalRepository` implements deterministic ordering by target date, name, and stable goal id.

`CalculateGoalProgress` is the authoritative derived calculation for goal progress. It:

- accepts an existing `Goal`
- calculates remaining amount as `targetAmount - currentAmount`
- calculates completion from exact `currentAmount == targetAmount`
- exposes a deterministic Decimal `progressRatio`
- treats a zero target as completed progress
- does not use `targetDate` for completion

`GoalsView` is currently a `ContentUnavailableView` placeholder reached from `MoreView`.

`AppDependencies` already owns shared repositories and calculators for other features. It should be extended to carry `GoalRepository` and `CalculateGoalProgress` explicitly to the Goals feature.

## GoalID References

The current app source stores `GoalID` only in:

- `Goal`
- `GoalRepository`
- goal persistence models/repository

No current aggregate stores a foreign `GoalID`. Goal deletion can therefore call `GoalRepository.deleteGoal(id:)` directly after native destructive confirmation.

If a future `GoalID` reference is added, deletion safety must be re-evaluated before broadening behavior.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/Goals/
```

Use feature-owned presentation/state types where useful:

```text
Goals/
└── Presentation/
```

The feature may introduce a focused `@Observable` state object for goal list, derived progress state, editor state, detail route, and deletion state.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct repositories inside feature views
- persist remaining amount, completion, ratio, or any derived progress
- duplicate rules owned by `Goal`, `Money`, or `CalculateGoalProgress`
- introduce a generic CRUD, MVVM, or confirmation framework
- redesign dependency injection globally

Use explicit dependency injection from the app composition layer. `GoalsView` should receive `GoalRepository` and `CalculateGoalProgress` through `MoreView`.

## Feature Behavior

### Goal List

The Goals root screen must:

- load goals from `GoalRepository.fetchGoals()`
- preserve deterministic repository ordering
- derive progress for each goal using `CalculateGoalProgress`
- show name
- show target amount
- show current amount
- show remaining amount
- show completion state as text, not color alone
- show target date when present
- support empty state
- support loading state
- surface repository or progress-calculation failures

Do not add charts, projections, contribution history, account linkage, analytics, or custom visual design.

### Create Goal

Goal creation must allow entry of:

- name
- target amount
- current amount
- currency
- optional target date

Creation must construct:

- target `Money`
- current `Money`
- `Goal`

through their validated initializers, then persist through `GoalRepository.save(_:)`.

SwiftUI must not duplicate finance-domain validation rules.

### Money Input

Do not use `Double` or `Float` for monetary values.

Use a local Decimal-oriented text parser matching the Accounts, Transactions, and Budgets feature approach:

- trim input
- reject empty input
- respect the current locale decimal separator
- reject malformed input
- parse into `Decimal` exactly

Currency should be a text field normalized by `Money`; the UI should surface invalid currency through the editor error path.

Do not change persistence Decimal semantics.

### Edit Goal

Editing must allow changing:

- name
- target amount
- current amount
- currency
- optional target date

Editing must preserve the existing `GoalID`.

Editing must construct a `Goal` through its validated domain initializer and save through `GoalRepository.save(_:)`.

Target date must be clearable.

Do not recreate identity during editing.

### Delete Goal

Deletion is allowed through `GoalRepository.deleteGoal(id:)` because no current aggregate stores `GoalID`.

Use native destructive confirmation before delete.

Deletion must not cascade changes into other aggregates.

Cancellation must perform no delete.

### Goal Detail

Provide a native detail view showing:

- name
- target amount
- current amount
- remaining amount
- completion state
- progress ratio from `CalculateGoalProgress`
- target date when present

The detail view must not access persistence directly and must not persist derived values.

Do not add contribution history, projections, account linkage, alerts, or charts.

## State

Use SwiftUI Observation (`@Observable`) where it provides clear value.

State should cover:

- goal list loading
- per-goal progress values
- surfaced errors
- presented editor state
- selected detail route
- deletion confirmation state

Business rules remain in domain types and finance workflows.

Do not create separate observable objects for trivial leaf views.

## Concurrency

Repository calls are async. `CalculateGoalProgress` is synchronous and pure, but may throw.

Feature state that drives SwiftUI must be `@MainActor` isolated.

Do not weaken repository or calculator `Sendable` contracts.

Keep SwiftData and persistence details behind repository interfaces.

## Accessibility

Use native semantic SwiftUI controls.

Ensure:

- goal rows have meaningful labels
- progress and completion are understandable without color alone
- editor fields have labels
- destructive delete is identifiable
- buttons have accessible names
- Dynamic Type is not obviously broken

A full accessibility audit is intentionally deferred.

## UI

Use native SwiftUI components:

- `List`
- `Form`
- `sheet`
- `navigationDestination`
- `confirmationDialog`
- `ContentUnavailableView`
- toolbar buttons

Do not add:

- custom design system
- charts
- decorative animations
- bespoke navigation framework

## Testing Strategy

Add focused presentation/state tests with repository and calculator test doubles. Do not use SwiftData where test doubles are sufficient.

Cover at minimum:

List:

- loads goals
- empty result
- load failure
- derives progress for each goal

Create:

- valid goal saves
- `GoalID` is preserved
- high-precision localized Decimal input is preserved
- optional target date is preserved
- nil target date is preserved
- invalid domain input does not save
- repository save failure surfaces

Edit:

- `GoalID` is preserved
- name update persists
- target amount update persists
- current amount update persists
- target date update persists
- target date can be cleared
- failed save surfaces

Delete:

- confirmed delete invokes repository
- cancellation does not delete
- failure surfaces

Detail:

- selection reaches goal detail state
- detail displays domain values and derived progress through feature state
- detail does not access persistence directly

Do not duplicate existing `GoalRepository` or `CalculateGoalProgress` tests.

## Scope

Do not add:

- contribution history
- recurring contributions
- account linkage
- projections
- milestone tracking
- alerts
- forecasting
- charts
- custom design system

If a new repository or architecture blocker is discovered, stop and report it before expanding scope.

## Final Implementation Notes

- Feature architecture: Goals uses `GoalsView`, `GoalsStore`, `GoalEditorView`, `GoalDetailView`, and goal presentation formatting under `App/Cairn/Features/Goals/Presentation/`.
- Dependency wiring: `AppDependencies` now carries `GoalRepository` and `CalculateGoalProgress`. `CairnApp` composes `SwiftDataGoalRepository`, and `RootView` passes the goal dependencies through `MoreView` into `GoalsView`.
- State ownership: `GoalsStore` is `@MainActor` and `@Observable`, owning list loading, per-goal progress, editor state, selected detail route, pending deletion, and surfaced errors.
- Progress integration: list and detail progress values are derived through `CalculateGoalProgress` via a focused `GoalProgressProvider` closure. The feature does not persist or manually calculate remaining amount, completion, or progress ratio.
- Create behavior: create parses Decimal target/current amounts using the locale-aware parser, constructs `Money` and `Goal` through validated initializers, supports optional target date, and saves through `GoalRepository`.
- Edit behavior: edit preserves `GoalID`, allows name, target amount, current amount, currency, and target date changes, supports clearing the target date, reconstructs the validated `Goal`, and saves through `GoalRepository`.
- Delete behavior: no current domain type stores a foreign `GoalID`, so deletion uses `GoalRepository.deleteGoal(id:)` after native destructive confirmation. The feature does not cascade into other aggregates. Cancellation performs no delete.
- Validation performed: feature validation is limited to Decimal text parsing. Domain rules remain owned by `Money`, `Goal`, and `CalculateGoalProgress`.
- Deferred behavior: contribution history, recurring contributions, account linkage, projections, milestone tracking, alerts, forecasting, charts, and custom visual design remain out of scope.

`Documentation/prompts/README.md` was updated with the completed Milestone 41 entry.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run focused Goals feature tests.
- Run `GoalTests`.
- Run `CalculateGoalProgressTests`.
- Show `git status --short`.
- Show the complete relevant diff.

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

## Review Focus

- No SwiftData or `ModelContext` leakage into views.
- Progress values are derived only through `CalculateGoalProgress`.
- Repository ordering is preserved.
- Create/edit preserve identity and domain validation.
- Delete performs no cascade and no delete on cancellation.
- Decimal parsing preserves precision and locale behavior.
- Error handling does not silently substitute fake progress.
- Feature state remains `@MainActor` and explicit.

## Commit Intent

Commit the Goals feature, focused tests, completed milestone documentation, and prompt README update after validation and manual review.
