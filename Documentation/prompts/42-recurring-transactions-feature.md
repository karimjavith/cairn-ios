# Milestone 42: Recurring Transactions Feature

Status: completed

## Objective

Replace the Recurring Transactions placeholder with a functional recurring-transaction management feature.

The feature must support:

- recurring transaction list
- create recurring transaction
- edit recurring transaction
- delete recurring transaction
- recurring transaction detail
- derived next occurrence

The feature must reuse the existing `RecurringTransaction`, `RecurringTransactionRepository`, `RecurringTransactionSchedule`, and `AccountRepository` boundaries. It must not persist derived next occurrence values or duplicate recurrence/domain validation in SwiftUI.

## Existing Context

The recurring transaction domain model exists in `App/Cairn/Core/Finance/RecurringTransaction.swift`.

`RecurringTransaction` is a validated value type with:

- stable `RecurringTransactionID`
- `AccountID`
- `TransactionDirection`
- non-negative `Money`
- `RecurrenceFrequency`
- start date
- optional end date
- optional trimmed memo

The current domain does not include `categoryID`. This milestone must not add category linkage.

`RecurringTransactionRepository` defines async recurring transaction persistence operations:

- `fetchRecurringTransactions()`
- `fetchRecurringTransaction(id:)`
- `save(_:)`
- `deleteRecurringTransaction(id:)`

`SwiftDataRecurringTransactionRepository` implements deterministic ordering by:

- start date ascending
- non-nil end date before nil
- end date ascending where both are non-nil
- stable recurring transaction id UUID string

`RecurringTransactionSchedule` is the authoritative scheduling calculator. It:

- is initialized with a `RecurringTransaction` and explicit `Calendar`
- exposes `nextOccurrence(after:)`
- exposes bounded `occurrences(in:)`
- uses strict-after next-occurrence semantics
- treats configured `endDate` as exclusive
- uses calendar arithmetic rather than seconds-based recurrence

`RecurringTransactionsView` is currently a `ContentUnavailableView` placeholder reached from `MoreView`.

`AppDependencies` owns shared repositories and workflow/calculation dependencies for other features. It should be extended to carry `RecurringTransactionRepository` and a production calendar for recurring scheduling.

## RecurringTransactionID References

The current app source stores `RecurringTransactionID` only in:

- `RecurringTransaction`
- `RecurringTransactionRepository`
- recurring transaction persistence models/repository
- recurring transaction tests

No current aggregate stores a foreign `RecurringTransactionID`. Recurring transaction deletion can therefore call `RecurringTransactionRepository.deleteRecurringTransaction(id:)` directly after native destructive confirmation.

If a future recurring-transaction reference is added, deletion safety must be re-evaluated before broadening behavior.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/RecurringTransactions/
```

Use feature-owned presentation/state types where useful:

```text
RecurringTransactions/
└── Presentation/
```

The feature may introduce a focused `@Observable` state object for recurring transaction list, account metadata, derived next occurrences, editor state, detail route, and deletion state.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct repositories inside feature views
- persist next occurrence or generated transaction state
- duplicate rules owned by `RecurringTransaction`, `Money`, or `RecurringTransactionSchedule`
- introduce a generic CRUD, MVVM, scheduling, or confirmation framework
- redesign dependency injection globally

Use explicit dependency injection from the app composition layer. `RecurringTransactionsView` should receive `RecurringTransactionRepository`, `AccountRepository`, and an explicit production `Calendar` through `MoreView`.

## Feature Behavior

### Recurring Transaction List

The Recurring Transactions root screen must:

- load recurring transactions from `RecurringTransactionRepository.fetchRecurringTransactions()`
- load account choices/metadata from `AccountRepository.fetchAccounts()`
- preserve deterministic repository ordering
- derive next occurrence for each recurring transaction using `RecurringTransactionSchedule`
- show amount/currency
- show direction
- show account identity
- show recurrence frequency
- show start date
- show end date when present
- show memo when useful
- show derived next occurrence when one exists
- show "No next occurrence" when scheduling has ended
- support empty state
- support loading state
- surface repository or scheduling failures

Do not add generated occurrence history, forecasting, notifications, search, grouping, filters, charts, or custom visual design.

### Create Recurring Transaction

Creation must allow entry of:

- account
- direction
- amount
- recurrence frequency
- start date
- optional end date
- optional memo

Creation must construct:

- `Money`
- `RecurringTransaction`

through their validated initializers, then persist through `RecurringTransactionRepository.save(_:)`.

The selected account supplies the currency for `Money`, matching the transaction editor pattern. Do not add an independent currency field unless the domain later requires it.

SwiftUI must not duplicate finance-domain validation rules.

### Money Input

Do not use `Double` or `Float` for monetary values.

Use a local Decimal-oriented text parser matching the Accounts, Transactions, Budgets, and Goals feature approach:

- trim input
- reject empty input
- respect the current locale decimal separator
- reject malformed input
- parse into `Decimal` exactly

Do not change persistence Decimal semantics.

### Edit Recurring Transaction

Editing must allow changing:

- account
- direction
- amount
- frequency
- start date
- optional end date
- memo

Editing must preserve the existing `RecurringTransactionID`.

Editing must construct a `RecurringTransaction` through its validated domain initializer and save through `RecurringTransactionRepository.save(_:)`.

End date must be clearable.

Do not recreate identity during editing.

### Delete Recurring Transaction

Deletion is allowed through `RecurringTransactionRepository.deleteRecurringTransaction(id:)` because no current aggregate stores `RecurringTransactionID`.

Use native destructive confirmation before delete.

Deletion must not cascade changes into accounts, transactions, categories, budgets, goals, generated transactions, or any future derived state.

Cancellation must perform no delete.

Repository failures must surface.

### Recurring Transaction Detail

Provide a native detail view showing:

- account
- direction
- amount
- recurrence frequency
- start date
- end date when present
- memo when present
- derived next occurrence or no-next-occurrence state

The detail view must not access persistence directly and must not persist derived values.

Do not add generated occurrence history.

## Scheduling

Use `RecurringTransactionSchedule` exactly as the authoritative calculation for next occurrence.

Do not:

- calculate recurring dates manually in views
- persist next occurrence
- use an implicit `Calendar.current` inside scheduling
- generate `Transaction` values
- schedule notifications
- add background scheduling

Production scheduling should use a `Calendar` configured at the composition boundary. The app composition may use the user's normal calendar/time-zone semantics by explicitly providing `Calendar.autoupdatingCurrent`.

Tests must use a fixed `Calendar` and `TimeZone`.

List/detail next-occurrence derivation should use an explicit reference-date provider so tests remain deterministic and production can use the current date.

## State

Use SwiftUI Observation (`@Observable`) where it provides clear value.

State should cover:

- recurring transaction list loading
- account metadata loading
- per-recurring-transaction next occurrence values
- surfaced errors
- presented editor state
- selected detail route
- deletion confirmation state

Business rules remain in domain types and finance scheduling.

Do not create separate observable objects for trivial leaf views.

## Concurrency

Repository calls are async.

`RecurringTransactionSchedule` is synchronous and pure, but may throw.

Feature state that drives SwiftUI must be `@MainActor` isolated.

Do not introduce global state, detached tasks, or custom concurrency frameworks.

## Errors

Surface actionable feature errors for:

- recurring transaction load failures
- account load failures
- money parsing failures
- invalid account selection
- domain validation failures
- repository save/delete failures
- scheduling failures

Do not:

- silently replace repository failures with empty data
- silently replace scheduling failures with fake next occurrences
- pretend failed saves/deletes succeeded
- stringify arbitrary errors in UI
- introduce generic app-wide error infrastructure

## Accessibility

Use native semantic controls.

Ensure:

- recurring transaction rows expose amount, direction, account, frequency, and next occurrence meaningfully
- direction is expressed as text, not color alone
- editor fields are labeled
- destructive actions are clearly identified
- Dynamic Type is not obviously constrained

Full accessibility audit remains later.

## Testing

Use repository test doubles for feature/state tests.

Do not use SwiftData for presentation/state tests.

Cover at minimum:

List:

- loads recurring transactions
- empty result
- load failure
- account display metadata resolves
- next occurrence is derived

Create:

- valid recurring transaction saves
- identity preserved
- account preserved
- direction preserved
- localized fractional amount preserved
- frequency preserved
- dates preserved
- nil end date preserved
- memo preserved
- invalid input does not save
- repository save failure surfaces

Edit:

- `RecurringTransactionID` preserved
- account update persists
- direction update persists
- amount update preserves Decimal precision
- frequency update persists
- start date update persists
- end date nil to non-nil persists
- end date non-nil to nil persists
- memo update and clear persist
- failed save surfaces

Delete:

- confirmed delete invokes repository
- cancellation does not delete
- failure surfaces

Detail/scheduling:

- next occurrence uses `RecurringTransactionSchedule`
- ended recurrence shows no next occurrence
- detail route exposes domain data without persistence access

Do not duplicate `RecurringTransactionRepository` or `RecurringTransactionSchedule` tests.

## Scope

Do not add:

- automatic `Transaction` generation
- missed-occurrence reconciliation
- notifications
- recurrence exceptions
- custom recurrence rules
- generated history
- forecasting
- category linkage
- background scheduling
- search
- advanced filters
- charts
- custom design system

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- focused Recurring Transactions feature tests
- existing `RecurringTransactionTests`
- existing `RecurringTransactionScheduleTests`
- extra focused tests only when directly affected
- show `git status --short`
- show the relevant diff

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

Do not stage or commit during implementation.

## Review Focus

- No SwiftData or `ModelContext` leakage into views.
- Explicit dependency injection through `AppDependencies`.
- Correct use of `RecurringTransactionSchedule` with explicit `Calendar`.
- Deterministic tests with fixed calendar/time zone and reference date.
- No persisted next occurrence.
- No generated transactions.
- Correct preservation of `RecurringTransactionID` during edit.
- Correct account-derived currency behavior.
- Correct end date creation, update, and clearing.
- Delete confirmation and cancellation behavior.
- Repository and scheduling failures are visible.

## Final Implementation

The feature was implemented under:

```text
App/Cairn/Features/RecurringTransactions/Presentation/
```

The final feature types are:

- `RecurringTransactionsView`
- `RecurringTransactionsStore`
- `RecurringTransactionEditorState`
- `RecurringTransactionEditorView`
- `RecurringTransactionDetailView`
- `RecurringTransactionPresentationFormatting`

The root view owns one `@State` store. The store owns list loading, account metadata, derived next occurrences, editor state, delete confirmation state, and detail routing.

Views remain native SwiftUI and do not access SwiftData, `ModelContext`, or concrete persistence repositories.

## Final Dependency Wiring

`AppDependencies` now carries:

- `RecurringTransactionRepository`
- explicit recurring transaction `Calendar`

`CairnApp` wires:

- `SwiftDataRecurringTransactionRepository(modelContainer:)`
- `Calendar.autoupdatingCurrent`

`RootView` passes those dependencies to `MoreView`.

`MoreView` passes `RecurringTransactionRepository`, `AccountRepository`, and the explicit calendar to `RecurringTransactionsView`.

This keeps scheduler calendar/time-zone configuration at the composition boundary while allowing deterministic tests to use a fixed calendar/time zone.

## Final State Ownership

`RecurringTransactionsStore` is `@MainActor` and `@Observable`.

It owns:

- loaded recurring transactions
- loaded accounts
- next occurrence values keyed by `RecurringTransactionID`
- loading/error state
- editor presentation
- pending deletion
- detail route

Leaf views receive values and callbacks only.

## Final Create/Edit/Delete Behavior

Create and edit both construct `Money` and `RecurringTransaction` through validated domain initializers.

Create/edit support:

- account selection
- direction
- amount
- recurrence frequency
- start date
- optional end date
- memo

The selected account supplies the money currency.

Edit preserves `RecurringTransactionID`.

End date and memo can be cleared.

Delete uses native destructive confirmation and calls `RecurringTransactionRepository.deleteRecurringTransaction(id:)` directly because no current aggregate stores `RecurringTransactionID`.

Cancellation performs no delete.

Repository failures surface through feature error state.

## Final Scheduling Integration

Next occurrence is derived during list load by default through:

```swift
RecurringTransactionSchedule(recurringTransaction: recurringTransaction, calendar: calendar)
    .nextOccurrence(after: referenceDate)
```

The store accepts a small feature-local next-occurrence provider and reference-date provider for deterministic tests.

Production uses the injected app calendar and current date.

Ended recurrences show no next occurrence.

Next occurrence is never persisted.

## Validation Performed

Validation is performed by:

- `RecurringTransactionsStoreTests`
- existing `RecurringTransactionTests`
- existing `RecurringTransactionScheduleTests`
- generic iOS Simulator build
- `git -c core.fsmonitor=false diff --check`

Feature tests use repository doubles and deterministic scheduling inputs rather than SwiftData.

## Deferred Behavior

The milestone intentionally does not add:

- automatic `Transaction` generation
- missed-occurrence reconciliation
- notifications
- recurrence exceptions
- custom recurrence rules
- generated history
- forecasting
- category linkage
- background scheduling
- search
- filters
- charts
- custom visual design
