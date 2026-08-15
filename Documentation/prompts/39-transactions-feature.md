# Milestone 39: Transactions Feature

Status: completed

## Objective

Replace the Transactions placeholder with a functional Transactions feature.

The Transactions feature must support:

- transaction list
- create transaction
- edit transaction
- delete transaction
- transaction detail

The feature must reuse the existing `Transaction`, `TransactionRepository`, `SwiftDataTransactionRepository`, `AccountRepository`, `CategoryRepository`, and `CreateTransaction` boundaries. It must not duplicate transaction or create-workflow validation in SwiftUI.

## Existing Context

The transaction domain model exists in `App/Cairn/Core/Finance/Transaction.swift`.

`Transaction` is a validated value type with:

- stable `TransactionID`
- required `AccountID`
- `TransactionDirection`
- non-negative `Money`
- occurrence date
- optional `CategoryID`
- normalized optional memo

`TransactionRepository` defines async transaction persistence and query operations:

- `fetchTransactions(accountID:)`
- `fetchTransactions(categoryID:)`
- `fetchTransactions(occurredFrom:occurredBefore:)`
- `fetchTransaction(id:)`
- `save(_:)`
- `deleteTransaction(id:)`

`SwiftDataTransactionRepository` implements deterministic ordering for transaction queries by `occurredAt` descending and then stable transaction id ordering. It updates existing records by id when `save(_:)` is called and deletes only the transaction record addressed by `TransactionID`.

`CreateTransaction` owns create-only workflow semantics:

- account existence check
- account/transaction currency consistency
- duplicate `TransactionID` rejection before save
- transaction domain construction
- persistence through `TransactionRepository.save(_:)`

Milestone 31A intentionally did not validate category existence in `CreateTransaction`. The Transactions feature may restrict UI category selection to loaded categories, but must not change the workflow contract.

Milestone 34A intentionally did not add unrestricted `fetchAll()`. The list in this milestone will use the existing bounded occurred-date query with finite `Date.distantPast` and `Date.distantFuture` bounds to display all transactions available through current repository capabilities without adding a new repository contract.

`TransactionsView` is currently a `ContentUnavailableView` placeholder.

`AppDependencies` already owns account, category, and transaction repositories. It should be extended only as needed to provide `CreateTransaction` to the Transactions feature.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/Transactions/
```

Use feature-owned presentation/state types where useful:

```text
Transactions/
├── Presentation/
└── Support/   optional, only if needed
```

The feature may introduce a focused `@Observable` state object for transaction list, metadata, editor, detail route, and deletion state.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct repositories inside feature views
- duplicate business rules already owned by `Transaction`, `Money`, or `CreateTransaction`
- introduce a generic CRUD or MVVM framework abstraction
- redesign dependency injection globally

Use explicit dependency injection from the app composition layer. `TransactionsView` should receive `TransactionRepository`, `AccountRepository`, `CategoryRepository`, and `CreateTransaction`.

## Feature Behavior

### Transaction List

The Transactions root screen must:

- load transactions from `TransactionRepository.fetchTransactions(occurredFrom:occurredBefore:)`
- use finite distant-past/distant-future bounds rather than adding `fetchAll()`
- preserve deterministic repository ordering
- load accounts from `AccountRepository`
- load categories from `CategoryRepository`
- show amount and currency
- show direction in text, not color alone
- show occurrence date
- show account identity from loaded accounts when available
- show category identity from loaded categories when present and available
- show memo when present and useful
- support empty state
- support loading state
- surface transaction, account, or category load failures

Do not add search, advanced filtering, pagination, charts, grouping, or analytics.

### Create Transaction

Transaction creation must allow entry of:

- account
- direction
- amount
- occurred date
- optional category
- optional memo

Creation must call the existing `CreateTransaction` workflow.

The editor should only allow selecting accounts and categories loaded into feature state. A missing account selection is a feature input failure and must not call `CreateTransaction`.

Category selection may be nil. When a category is selected, it must come from loaded categories.

SwiftUI may validate field presence enough to drive basic UI state, but it must not duplicate `Transaction`, `Money`, or `CreateTransaction` validation rules.

### Money Input

Do not use `Double` or `Float` for monetary values.

Use a local Decimal-oriented text parser matching the Accounts feature approach:

- trim input
- reject empty input
- respect the current locale decimal separator
- reject malformed input
- parse into `Decimal` exactly

Use the selected account currency for transaction `Money`. The editor must not expose an independent transaction currency field in this milestone, because `CreateTransaction` already enforces account currency consistency.

Do not change persistence Decimal semantics.

### Edit Transaction

Editing must allow changing:

- account
- direction
- amount
- occurred date
- optional category
- optional memo

Editing must preserve the existing `TransactionID`.

Editing must construct a `Transaction` through its validated domain initializer and save through `TransactionRepository.save(_:)`.

Editing must not use `CreateTransaction`, because that workflow has duplicate-ID create semantics and would reject the existing transaction id.

The edit path should perform the smallest explicit account/currency consistency check needed before save:

- selected account must come from loaded accounts
- transaction `Money.currencyCode` must use the selected account currency

Do not broaden repository contracts unless a genuine blocker is discovered.

### Delete Transaction

Deletion is allowed through `TransactionRepository.deleteTransaction(id:)`.

Use native destructive confirmation before delete.

Deletion must not cascade changes into:

- `Account`
- `Budget`
- `Goal`
- `Category`
- `RecurringTransaction`

Derived values such as account balance and budget progress should reflect the deletion later because they are calculated from transactions.

Cancellation must perform no delete.

### Transaction Detail

Provide a native detail view showing the transaction's existing domain data:

- amount and currency
- direction
- date
- account identity
- category identity or uncategorized state
- memo when present

The detail view must not access persistence directly.

Do not add account transaction history, budget impact summaries, cash-flow analytics, or linked recurring transaction history.

## State

Use SwiftUI Observation (`@Observable`) where it provides clear value.

State should cover:

- transaction list loading
- account/category metadata loading
- surfaced errors
- presented editor state
- selected detail route
- deletion confirmation state

Business rules remain in domain types and use cases.

Do not create separate observable objects for trivial leaf views.

## Concurrency

Repository and workflow calls are async.

Feature state that drives SwiftUI must be `@MainActor` isolated.

Do not weaken repository or workflow `Sendable` contracts.

Keep SwiftData and persistence details behind repository interfaces.

## Accessibility

Use native semantic SwiftUI controls.

Ensure:

- transaction rows have meaningful labels
- amount and direction can be understood without color alone
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
- custom colors
- charts
- decorative animations
- bespoke navigation framework

## Testing Strategy

Add focused presentation/state tests with repository and workflow test doubles. Do not use SwiftData where test doubles are sufficient.

Cover at minimum:

List:

- loads transactions
- empty result
- load failure
- account/category display metadata resolves correctly

Create:

- valid transaction is created through `CreateTransaction`
- `TransactionID` is preserved
- account selection is preserved
- optional category is preserved
- nil category is preserved
- localized fractional amount is accepted
- invalid input does not save
- `CreateTransaction` failure surfaces

Edit:

- preserves `TransactionID`
- updated account persists
- updated category persists
- category can change to nil
- updated direction persists
- updated amount preserves Decimal precision
- updated date persists
- updated memo persists
- failed update surfaces

Delete:

- confirmed delete calls repository
- cancellation does not delete
- delete failure surfaces

Detail/navigation:

- selection reaches transaction detail
- detail data is resolved from domain and loaded metadata without persistence access

Do not duplicate `TransactionRepository` CRUD tests.

## Scope

Do not add:

- transfers
- recurring generation
- attachment or receipt support
- split transactions
- transaction search
- advanced filters
- reconciliation
- pending or cleared states
- analytics
- charts

If a repository or architecture blocker is discovered, stop and report it before expanding scope.

## Documentation Updates

Final implementation notes:

- Feature architecture: Transactions uses `TransactionsView`, `TransactionsStore`, `TransactionEditorView`, `TransactionDetailView`, and transaction presentation formatting under `App/Cairn/Features/Transactions/Presentation/`.
- Dependency wiring: `AppDependencies` now creates and owns `CreateTransaction` from the existing account and transaction repositories. `RootView` passes `TransactionRepository`, `AccountRepository`, `CategoryRepository`, and `CreateTransaction` into `TransactionsView`.
- State ownership: `TransactionsStore` is `@MainActor` and `@Observable`, owning list loading, account/category metadata, editor state, selected detail route, pending deletion, and surfaced errors. Confirmed deletion receives the captured transaction explicitly so SwiftUI dialog-dismissal timing cannot clear the transaction before the async delete runs.
- Create vs edit semantics: create calls `CreateTransaction` and therefore preserves create-only duplicate-ID semantics. edit preserves the existing `TransactionID`, constructs `Transaction` through its domain initializer, and saves through `TransactionRepository.save(_:)`.
- Money input behavior: transaction amount parsing uses a local Decimal parser matching the Accounts approach, respects the current locale decimal separator, rejects empty or malformed input, and uses the selected account currency for `Money`.
- Validation performed: selected account must be loaded; selected category must either be nil or loaded; domain validation remains owned by `Money`, `Transaction`, and `CreateTransaction`.
- Intentionally deferred behavior: no transfers, recurring generation, attachments, splits, search, advanced filters, reconciliation, pending/cleared states, analytics, charts, account history, or budget impact summaries.

`Documentation/prompts/README.md` is updated consistently.

## Validation

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused Transactions feature tests
4. existing `TransactionTests`
5. existing `CreateTransactionTests`

Run additional focused tests only when directly affected.

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

Do not stage or commit.
