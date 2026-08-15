# Milestone 38: Categories Feature

Status: completed

## Objective

Replace the Categories placeholder with a functional category-management feature.

The Categories feature must support:

- category list
- create category
- edit category
- delete category

The feature must reuse the existing `Category`, `CategoryRepository`, `SwiftDataCategoryRepository`, and category persistence boundaries. It must not duplicate category validation in SwiftUI.

## Existing Context

The category domain model exists in `App/Cairn/Core/Finance/Category.swift`.

`Category` is a validated value type with:

- stable `CategoryID`
- trimmed non-empty name
- `CategoryKind` metadata with `income` and `expense`

`CategoryRepository` defines the async CRUD contract:

- `fetchCategories()`
- `fetchCategory(id:)`
- `save(_:)`
- `deleteCategory(id:)`

`SwiftDataCategoryRepository` implements the contract behind the repository boundary. It fetches categories deterministically by name then id, updates existing records by id, and deletes only the category record addressed by `CategoryID`.

`CategoriesView` is currently a `ContentUnavailableView` placeholder.

Milestone 37 introduced `AppDependencies` and explicit app composition for the Accounts feature. Categories should use the same composition root style without introducing a service locator, global store, or view-owned repository construction.

## Category References

The existing domain references `CategoryID` from:

- `Transaction.categoryID`, optional
- `Budget.categoryID`, required

`RecurringTransaction` does not currently carry a `CategoryID`.

The existing repository contracts can determine deletion references by:

- calling `TransactionRepository.fetchTransactions(categoryID:)`
- calling `BudgetRepository.fetchBudgets()` and filtering by `categoryID`

This is sufficient for this milestone's deletion policy without broadening repository contracts.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/Categories/
```

Use feature-owned presentation/state types where useful:

```text
Categories/
└── Presentation/
```

The feature may introduce a focused `@Observable` state object for list, editor, and deletion state. Categories is simpler than Accounts and does not need detail navigation or balance-loading state.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct `SwiftDataCategoryRepository` inside feature views
- put business rules in views
- introduce a global app store
- introduce a generic CRUD or MVVM framework abstraction
- redesign dependency injection globally

Use explicit dependency injection from the app composition layer. Extend `AppDependencies` only as needed to pass `CategoryRepository`, `TransactionRepository`, and `BudgetRepository` into `CategoriesView`.

## Feature Behavior

### Category List

The Categories root screen must:

- load categories from `CategoryRepository`
- preserve deterministic repository ordering
- show category name
- show category kind as native text metadata
- support empty state
- support loading state
- surface repository load failures

Do not add search, grouping, filtering, reordering, icons, colors, custom styling, or spending totals.

### Create Category

Category creation must allow entry of:

- name
- kind

The feature must construct `Category` through its validated domain initializer and persist through `CategoryRepository.save(_:)`.

SwiftUI must not duplicate `Category` validation rules.

### Edit Category

Editing must allow changing:

- name
- kind

Editing must preserve the existing `CategoryID` and save through `CategoryRepository.save(_:)`.

### Delete Category

Deletion must be explicit and user initiated.

Use native confirmation behavior before destructive deletion.

Before calling `CategoryRepository.deleteCategory(id:)`, the feature must:

- fetch transactions by `CategoryID`
- fetch budgets and check for matching `Budget.categoryID`

If any transaction or budget references the category, deletion must be blocked and surfaced as a typed Categories feature error. This milestone does not cascade-delete financial entities, mutate transactions or budgets, set category references to nil, or add reassignment behavior.

If reference checks fail, deletion must not proceed and the failure must surface.

If no references exist, deletion may call `CategoryRepository.deleteCategory(id:)`.

Cancellation must perform no delete and no reference checks.

## State

Use SwiftUI Observation (`@Observable`) where it provides clear value.

State should cover:

- category list loading
- surfaced errors
- presented editor state
- deletion confirmation state
- typed blocked-delete state

Business rules remain in domain types and repository-backed application logic.

Do not create separate observable objects for trivial leaf views.

## Concurrency

Repository calls are async.

Feature state that drives SwiftUI must be `@MainActor` isolated.

Do not weaken repository `Sendable` contracts.

Keep SwiftData and persistence details behind repository interfaces.

## Accessibility

Use native semantic SwiftUI controls.

Ensure:

- category rows have meaningful labels
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
- `confirmationDialog`
- `ContentUnavailableView`
- toolbar buttons

Do not add:

- custom design system
- custom colors unless already domain-owned
- category icons or emoji
- charts
- decorative animations
- bespoke navigation framework

## Testing Strategy

Add focused presentation/state tests with repository test doubles. Do not use SwiftData where test doubles are sufficient.

Cover at minimum:

List:

- loads categories
- empty result
- repository load failure

Create:

- valid category saves
- identity is preserved
- invalid domain input does not save
- repository save failure surfaces

Edit:

- `CategoryID` is preserved
- changed values save
- failed save does not pretend success

Delete:

- unreferenced category deletes
- transaction-referenced category is blocked
- budget-referenced category is blocked
- delete repository is not called when blocked
- transaction reference-query failure surfaces
- budget reference-query failure surfaces
- delete failure surfaces
- cancellation performs no delete

Do not duplicate existing `CategoryRepository` CRUD tests.

## Scope

Do not add:

- category spending totals
- transaction filtering UI
- budget UI
- category hierarchy
- subcategories
- icons or emojis
- category colors
- automatic categorization
- category merge
- reassignment workflows

If a new `CategoryID` reference is discovered that cannot be checked with existing repository contracts, stop and report the blocker before broadening scope.

## Documentation Updates

Final implementation notes:

- Feature architecture: Categories uses `CategoriesView`, `CategoriesStore`, `CategoryEditorView`, and small category presentation formatting under `App/Cairn/Features/Categories/Presentation/`.
- Dependency wiring: `CairnApp` creates `SwiftDataCategoryRepository` and `SwiftDataBudgetRepository`; `AppDependencies` owns category and budget repositories; `RootView` passes them through `MoreView` into `CategoriesView`.
- State ownership: `CategoriesStore` is `@MainActor` and `@Observable`, owning list loading, editor state, pending deletion, surfaced messages, and typed blocked-delete errors.
- Deletion/reference policy: deletion is blocked when `TransactionRepository.fetchTransactions(categoryID:)` returns any transaction or when any fetched budget has the category id. Reference query failures and delete failures surface as feature errors; cancellation performs no repository calls.
- Validation performed: create/edit construct `Category` through the domain initializer, preserving `CategoryID` for edit and relying on domain validation for empty/whitespace names.
- Intentionally deferred behavior: no search, grouping, filtering, spending totals, transaction or budget UI, hierarchy, colors, icons, automatic categorization, merge, or reassignment workflow.

`Documentation/prompts/README.md` is updated consistently.

## Validation

Run:

1. `git -c core.fsmonitor=false diff --check`
2. a generic iOS Simulator build
3. focused Categories feature tests
4. existing `CategoryTests`

Run additional focused tests only when directly affected.

Do not run the full `CairnTests` suite unless necessary.
