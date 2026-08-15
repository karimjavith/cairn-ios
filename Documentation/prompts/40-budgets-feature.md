# Milestone 40: Budgets Feature

Status: completed

## Objective

Replace the Budgets placeholder with a functional budget-management feature.

The Budgets feature must support:

- budget list
- derived budget progress
- create budget
- edit budget
- delete budget
- budget detail

The feature must reuse the existing `Budget`, `BudgetPeriod`, `BudgetRepository`, `CategoryRepository`, and `CalculateBudgetProgress` boundaries. It must not persist derived progress values or duplicate finance-domain validation in SwiftUI.

## Existing Context

The budget domain model exists in `App/Cairn/Core/Finance/Budget.swift`.

`Budget` is a validated value type with:

- stable `BudgetID`
- required `CategoryID`
- non-negative `Money` limit
- validated `BudgetPeriod`

`BudgetPeriod` requires `endDate > startDate`.

`BudgetRepository` defines async budget persistence operations:

- `fetchBudgets()`
- `fetchBudget(id:)`
- `save(_:)`
- `deleteBudget(id:)`

`CalculateBudgetProgress` is the authoritative derived calculation for budget progress. It:

- fetches the target budget by `BudgetID`
- fetches transactions by `Budget.categoryID`
- counts only outflow transactions
- applies `startDate <= occurredAt < endDate`
- validates matching currency for qualifying transactions
- returns derived `spent` and `remaining`
- does not clamp overspending

`CategoryRepository` provides the selectable category list for create/edit.

`BudgetsView` is currently a `ContentUnavailableView` placeholder.

`AppDependencies` already owns `BudgetRepository`, `CategoryRepository`, `TransactionRepository`, and derived calculators. It should be extended only as needed to pass `CalculateBudgetProgress` into the Budgets feature.

## BudgetID References

The current app source stores `BudgetID` only in:

- `Budget`
- `BudgetRepository`
- `CalculateBudgetProgress`
- budget persistence models/repository

No current aggregate stores a foreign `BudgetID`. Budget deletion can therefore call `BudgetRepository.deleteBudget(id:)` directly after native destructive confirmation.

If a future `BudgetID` reference is added, deletion safety must be re-evaluated before broadening behavior.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/Budgets/
```

Use feature-owned presentation/state types where useful:

```text
Budgets/
└── Presentation/
```

The feature may introduce a focused `@Observable` state object for budget list, progress state, category metadata, editor state, detail route, and deletion state.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct repositories inside feature views
- persist spent, remaining, or progress
- duplicate rules owned by `Budget`, `BudgetPeriod`, `Money`, or `CalculateBudgetProgress`
- introduce a generic CRUD, MVVM, or confirmation framework
- redesign dependency injection globally

Use explicit dependency injection from the app composition layer. `BudgetsView` should receive `BudgetRepository`, `CategoryRepository`, and `CalculateBudgetProgress`.

## Feature Behavior

### Budget List

The Budgets root screen must:

- load budgets from `BudgetRepository.fetchBudgets()`
- preserve deterministic repository ordering
- load categories from `CategoryRepository.fetchCategories()`
- derive progress for each budget using `CalculateBudgetProgress`
- show category identity
- show limit and currency
- show period
- show derived spent
- show derived remaining
- support empty state
- support loading state
- surface repository or progress-calculation failures

Do not add charts, transaction drill-downs, analytics, custom styling, or non-native progress visuals.

### Create Budget

Budget creation must allow entry of:

- category
- limit amount
- currency
- period start
- period end

The editor should only allow selecting categories loaded into feature state. Missing or stale category selection is a feature input failure and must not save.

Creation must construct:

- `Money`
- `BudgetPeriod`
- `Budget`

through their validated initializers, then persist through `BudgetRepository.save(_:)`.

SwiftUI must not duplicate finance-domain validation rules.

### Money Input

Do not use `Double` or `Float` for monetary values.

Use a local Decimal-oriented text parser matching the Accounts and Transactions feature approach:

- trim input
- reject empty input
- respect the current locale decimal separator
- reject malformed input
- parse into `Decimal` exactly

Currency should be a text field normalized by `Money`; the UI should surface invalid currency through the editor error path.

Do not change persistence Decimal semantics.

### Edit Budget

Editing must allow changing:

- category
- limit amount
- currency
- period start
- period end

Editing must preserve the existing `BudgetID`.

Editing must construct a `Budget` through its validated domain initializer and save through `BudgetRepository.save(_:)`.

Do not recreate identity during editing.

### Delete Budget

Deletion is allowed through `BudgetRepository.deleteBudget(id:)` because no current aggregate stores `BudgetID`.

Use native destructive confirmation before delete.

Deletion must not cascade changes into:

- transactions
- categories
- accounts
- goals
- recurring transactions

Cancellation must perform no delete.

### Budget Detail

Provide a native detail view showing:

- category identity
- limit
- period
- derived spent
- derived remaining

The detail view must not access persistence directly and must not persist derived values.

Do not add transaction drill-down, category spending charts, forecasts, or budget impact analytics.

## State

Use SwiftUI Observation (`@Observable`) where it provides clear value.

State should cover:

- budget list loading
- category metadata loading
- per-budget progress values
- surfaced errors
- presented editor state
- selected detail route
- deletion confirmation state

Business rules remain in domain types and finance workflows.

Do not create separate observable objects for trivial leaf views.

## Concurrency

Repository and calculation calls are async.

Feature state that drives SwiftUI must be `@MainActor` isolated.

Do not weaken repository or calculator `Sendable` contracts.

Keep SwiftData and persistence details behind repository interfaces.

## Accessibility

Use native semantic SwiftUI controls.

Ensure:

- budget rows have meaningful labels
- limit, spent, and remaining are understandable without color alone
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

- loads budgets
- empty result
- load failure
- derives progress for each budget
- progress failure surfaces

Create:

- valid budget saves
- `BudgetID` is preserved
- category is preserved
- high-precision localized Decimal input is preserved
- valid period is preserved
- invalid `Money`, `BudgetPeriod`, or `Budget` input does not save
- repository failure surfaces

Edit:

- `BudgetID` is preserved
- category update persists
- limit update persists
- period update persists
- failed save surfaces

Delete:

- confirmed delete invokes repository
- cancellation does not delete
- failure surfaces

Detail:

- selection reaches budget detail state
- detail displays domain values and derived progress through feature state
- detail does not access persistence directly

Do not duplicate existing `BudgetRepository` or `CalculateBudgetProgress` tests.

## Scope

Do not add:

- rollover
- recurring budgets
- budget alerts
- forecasts
- category spending charts
- transaction lists
- per-account budgets
- analytics
- custom design system

If a new repository or architecture blocker is discovered, stop and report it before expanding scope.

## Final Implementation Notes

- Feature architecture: Budgets uses `BudgetsView`, `BudgetsStore`, `BudgetEditorView`, `BudgetDetailView`, and budget presentation formatting under `App/Cairn/Features/Budgets/Presentation/`.
- Dependency wiring: `AppDependencies` now constructs `CalculateBudgetProgress` from `BudgetRepository` and `TransactionRepository`. `RootView` injects `BudgetRepository`, `CategoryRepository`, and `CalculateBudgetProgress` into `BudgetsView`.
- State ownership: `BudgetsStore` is `@MainActor` and `@Observable`, owning list loading, category metadata, per-budget progress, editor state, selected detail route, pending deletion, and surfaced errors.
- Progress integration: list and detail progress values are loaded through `CalculateBudgetProgress` via a focused async `BudgetProgressProvider` closure. The feature does not persist or manually calculate `spent` or `remaining`.
- Create behavior: create loads selectable categories from `CategoryRepository`, parses Decimal limit text using the locale-aware parser, constructs `Money`, `BudgetPeriod`, and `Budget` through validated initializers, then saves through `BudgetRepository`.
- Edit behavior: edit preserves `BudgetID`, allows category, limit, currency, and period changes, reconstructs the validated `Budget`, and saves through `BudgetRepository`.
- Delete behavior: no current domain type stores a foreign `BudgetID`, so deletion uses `BudgetRepository.deleteBudget(id:)` after native destructive confirmation. The feature does not cascade into transactions or categories. Cancellation performs no delete.
- Validation performed: feature validation is limited to selection presence/staleness and Decimal text parsing. Domain rules remain owned by `Money`, `BudgetPeriod`, `Budget`, and `CalculateBudgetProgress`.
- Deferred behavior: rollover, recurring budgets, alerts, forecasts, transaction drill-down, category spending charts, per-account budgets, analytics, and custom visual design remain out of scope.

`Documentation/prompts/README.md` was updated with the completed Milestone 40 entry.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run focused Budgets feature tests.
- Run `BudgetTests`.
- Run `CalculateBudgetProgressTests`.
- Show `git status --short`.
- Show the complete relevant diff.

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

## Review Focus

- No SwiftData or `ModelContext` leakage into views.
- Progress values are derived only through `CalculateBudgetProgress`.
- Repository ordering is preserved.
- Create/edit preserve identity and domain validation.
- Delete performs no cascade and no delete on cancellation.
- Decimal parsing preserves precision and locale behavior.
- Error handling does not silently substitute zero progress.
- Feature state remains `@MainActor` and explicit.

## Commit Intent

Commit the Budgets feature, focused tests, completed milestone documentation, and prompt README update after validation and manual review.
