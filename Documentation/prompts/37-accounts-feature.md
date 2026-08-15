# Milestone 37: Accounts Feature

Status: completed

## Objective

Replace the Accounts placeholder with Cairn's first functional feature.

The Accounts feature must support:

- account list
- account current balance display
- create account
- edit account
- delete account
- account detail

The feature must use the existing `Account`, `AccountRepository`, `SwiftDataAccountRepository`, and `CalculateAccountBalance` boundaries. It must not duplicate account validation, money validation, or balance calculation logic in SwiftUI.

## Existing Context

The account domain model already exists in `App/Cairn/Core/Finance/Account.swift`.

`Account` is a validated value type with:

- stable `AccountID`
- trimmed non-empty name
- `AccountType`
- normalized ISO currency code
- `Money` opening balance
- currency consistency between `currencyCode` and `openingBalance`

`AccountRepository` already defines the async CRUD contract:

- `fetchAccounts()`
- `fetchAccount(id:)`
- `save(_:)`
- `deleteAccount(id:)`

`SwiftDataAccountRepository` already implements the contract behind the repository boundary. It fetches accounts deterministically by name then id, updates existing records by id, and deletes only the account record addressed by `AccountID`.

`CalculateAccountBalance` already derives current balance by fetching the account, fetching transactions for the account id, and applying inflows and outflows to the account opening balance. Balance failures include missing account and transaction currency mismatch.

`AccountsView` is currently a `ContentUnavailableView` placeholder.

`CairnApp` currently owns the production `ModelContainer`, and `RootView` owns root tab navigation. The Accounts feature needs the smallest app-layer wiring change required to inject repository/use-case dependencies into `AccountsView`.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/Accounts/
```

Use feature-owned presentation/state types where they are useful:

```text
Accounts/
├── Presentation/
└── Support/   optional, only if needed
```

The feature may introduce a focused `@Observable` state object for account list/editor/detail state. It must keep presentation state separate from business rules.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct `SwiftDataAccountRepository` inside feature views
- put business rules in views
- introduce a global app store
- introduce a generic MVVM/framework abstraction
- redesign dependency injection globally

Use explicit dependency injection from the app composition layer. If app composition needs adjustment, add only the minimum app-owned dependency holder or factory required to pass `AccountRepository`, `TransactionRepository`, and `CalculateAccountBalance` into Accounts.

## Feature Behavior

### Account List

The Accounts root screen must:

- load accounts from `AccountRepository`
- preserve deterministic repository ordering
- show account name
- show account type in a simple native form
- show derived current balance using `CalculateAccountBalance`
- support empty state
- support loading state
- surface load or balance errors instead of replacing failures with fake data

Balance derivation must be explicit per account and must not store or persist a running account balance.

### Account Detail

Account detail must display:

- name
- account type
- currency
- opening balance
- derived current balance

No transaction list is included in this milestone. Transaction UI remains owned by the future Transactions feature.

### Create Account

Account creation must allow entry of:

- name
- account type
- opening balance
- currency

The feature must construct `Account` through its validated domain initializer and persist through `AccountRepository.save(_:)`.

SwiftUI may validate field presence enough to drive basic UI state, but it must not duplicate `Account` or `Money` validation rules.

### Edit Account

Editing must allow changing existing account values supported by the domain:

- name
- account type
- opening balance
- currency

Editing must preserve the existing `AccountID` and save through `AccountRepository.save(_:)`.

### Delete Account

Deletion must be explicit and user initiated.

Use native confirmation behavior before destructive deletion.

Deletion must check `TransactionRepository.fetchTransactions(accountID:)` before calling `AccountRepository.deleteAccount(id:)`.

If transactions reference the account id, deletion must be blocked and surfaced as a typed Accounts feature error. This milestone does not cascade-delete transactions, mutate transactions, or add a global deletion-policy framework.

If no transactions reference the account id, deletion may call `AccountRepository.deleteAccount(id:)`.

## Money Input

Do not use `Double` or `Float` for monetary values.

Use a local, Decimal-oriented text parsing strategy for the account editor.

User-entered monetary text must be locale-aware and accept the user's normal decimal separator.

Malformed monetary text must be surfaced as a validation failure and must not be silently coerced.

Currency handling must remain consistent with `Money`; `Money` owns ISO code validation and normalization.

Do not introduce a global money-input framework in this milestone.

## State

Use SwiftUI Observation (`@Observable`) for feature state where it provides clear value.

State should cover:

- account list loading
- per-account derived balances
- surfaced errors
- presented editor state
- selected detail/navigation state
- deletion confirmation state

Business rules remain in the domain types and use cases.

Do not create separate observable objects for trivial leaf views.

## Concurrency

Repository calls are async.

Feature state that drives SwiftUI must be `@MainActor` isolated.

Do not weaken repository `Sendable` contracts.

Keep SwiftData and persistence details behind repository interfaces.

## Accessibility

Use native semantic SwiftUI controls.

Ensure:

- account rows have meaningful labels
- destructive delete is identifiable
- text fields have labels
- buttons have accessible names
- Dynamic Type is not obviously broken

A full accessibility audit is intentionally deferred.

## UI

Use native SwiftUI components:

- `List`
- `NavigationStack` supplied by the app shell
- `Form`
- `sheet`
- `navigationDestination`
- `ContentUnavailableView`

Do not add:

- custom design system
- custom colors unless already part of assets
- charts
- decorative animations
- bespoke navigation framework

## Testing Strategy

Add focused presentation/state tests with repository test doubles. Do not use SwiftData where test doubles are sufficient.

Cover at minimum:

List/state:

- loads accounts
- empty state
- repository load failure
- derived balances are requested/calculated
- balance failure is surfaced rather than silently replaced with fake data

Create:

- valid account is saved
- `AccountID` is preserved from created domain value
- invalid input/domain failure does not save
- repository save failure surfaces

Edit:

- editing preserves `AccountID`
- changed values persist
- failed save does not pretend success

Delete:

- confirmed delete invokes repository
- failed delete surfaces
- cancellation does not delete

Navigation/detail:

- selecting account can reach detail state
- displayed detail derives current balance rather than storing a running balance

Do not duplicate existing `AccountRepository` CRUD tests.

## Scope

Do not add:

- transaction CRUD
- account transaction history
- transfers
- credit limits
- bank connectivity
- institution logos
- account grouping
- reordering
- search
- net worth/dashboard logic

If an architectural blocker is discovered, stop and report it before broadening scope.

## Documentation Updates

After implementation, update this milestone spec to `completed` and document:

- final feature architecture
- dependency wiring
- state ownership
- account deletion behavior
- validation performed
- intentionally deferred behavior

Update `Documentation/prompts/README.md` consistently.

## Validation

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused Accounts feature tests
4. existing `AccountTests`
5. existing `CalculateAccountBalanceTests`

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

Do not stage or commit.

## Completion Notes

## Final Feature Architecture

The Accounts feature now lives under `App/Cairn/Features/Accounts/`.

Production feature files are:

- `Presentation/AccountsView.swift`
- `Presentation/AccountsStore.swift`
- `Presentation/AccountDetailView.swift`
- `Presentation/AccountEditorView.swift`
- `Support/AccountPresentationFormatting.swift`

`AccountsView` owns native SwiftUI composition only. It renders the account list, empty state, loading state, editor sheet, detail navigation, and native delete confirmation.

`AccountsStore` is a focused `@MainActor @Observable` presentation-state owner. It coordinates async account loading, per-account derived balance loading, create/edit/delete actions, selected detail route, editor state, and surfaced errors.

Business rules remain in existing domain/use-case types:

- `Account`
- `Money`
- `AccountRepository`
- `CalculateAccountBalance`

SwiftUI views do not use SwiftData, `ModelContext`, or concrete repository implementations.

## Dependency Wiring

`CairnApp` still owns the single production SwiftData `ModelContainer`.

`AppDependencies` is a small app-layer dependency holder introduced to wire:

- `SwiftDataAccountRepository`
- `SwiftDataTransactionRepository`
- `CalculateAccountBalance`

`RootView` receives `AppDependencies` by constructor injection and passes the account repository and balance use case into `AccountsView`.

No global app store, service locator, singleton architecture, or generic dependency framework was introduced.

## State Ownership

Accounts feature state is owned by `AccountsStore`.

State covers:

- account collection
- loading state
- top-level error message
- per-account balance states
- current editor
- pending deletion
- selected detail route

`AccountEditorState` owns editable text/form state for create and edit flows. It constructs `Account` through the validated domain initializer when saving.

## Account Deletion Behavior

Deletion is explicit and user initiated.

The UI uses native confirmation before invoking `AccountRepository.deleteAccount(id:)`.

Before invoking `AccountRepository.deleteAccount(id:)`, `AccountsStore` checks `TransactionRepository.fetchTransactions(accountID:)`.

If one or more transactions reference the account id, deletion is blocked with an Accounts feature error and the account plus transactions remain unchanged.

If no transactions reference the account id, deletion proceeds through the existing repository contract.

This milestone does not cascade-delete transactions, mutate transaction records, add soft delete, or change repository delete semantics globally.

## Validation Performed

Validation is recorded in the final implementation response for this milestone.

Feature tests use repository test doubles rather than SwiftData.

## Validation Behavior

The editor parses monetary input through a local strict Decimal-oriented parser. It accepts the injected locale's normal decimal separator for user-entered text.

The parser does not use `Double` or `Float`.

Persistence Decimal representation remains locale-independent. Account persistence strings and repository behavior are unchanged.

Malformed or empty monetary text surfaces an editor error and does not save.

`Money` remains responsible for currency validation and normalization.

`Account` remains responsible for account name and account/currency consistency validation.

Repository save failures are surfaced and do not dismiss the editor.

Balance calculation failures are surfaced per account rather than replaced with fake balances.

## Intentionally Deferred Behavior

- transaction CRUD
- account transaction history
- transfers
- credit limits
- bank connectivity
- institution logos
- account grouping
- reordering
- search
- net worth/dashboard logic
- full accessibility audit
- global money-input framework
