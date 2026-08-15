# Milestone 43: Dashboard

Status: completed

## Objective

Replace the Dashboard placeholder with a functional financial overview that composes existing repository contracts and existing finance calculations.

The Dashboard should summarize:

- account balances
- per-currency account totals
- single-currency net worth only when truthful without FX conversion
- recent cash flow for a bounded recent period
- budget status
- goal status
- recent transactions from the existing bounded transaction query

The dashboard must not invent new financial semantics, persist derived state, or duplicate formulas owned by existing calculators.

## Existing Context

`DashboardView` is currently a `ContentUnavailableView` placeholder for the root Dashboard tab.

Existing dependencies and calculations:

- `AccountRepository.fetchAccounts()`
- `BudgetRepository.fetchBudgets()`
- `GoalRepository.fetchGoals()`
- `CategoryRepository.fetchCategories()`
- `TransactionRepository.fetchTransactions(occurredFrom:occurredBefore:)`
- `CalculateAccountBalance`
- `CalculateBudgetProgress`
- `CalculateGoalProgress`
- `CalculateCashFlowSummary`

`TransactionRepository.fetchTransactions(occurredFrom:occurredBefore:)` already provides the bounded date query needed for recent transactions. No repository contract broadening is required.

`AppDependencies` currently carries the repositories and most calculators used by feature screens. It should be extended to carry `CalculateCashFlowSummary` and an explicit dashboard calendar.

## Architecture

Feature code belongs under:

```text
App/Cairn/Features/Dashboard/
```

Use feature-owned presentation/state types:

```text
Dashboard/
└── Presentation/
```

The feature may introduce a focused `@Observable` state object for loading and derived dashboard snapshot state.

The feature must not:

- use SwiftData directly from SwiftUI views
- expose `ModelContext`
- construct repositories inside feature views
- persist account balances, net worth, cash-flow summaries, budget progress, goal progress, or recent transaction state
- duplicate formulas owned by `CalculateAccountBalance`, `CalculateBudgetProgress`, `CalculateGoalProgress`, or `CalculateCashFlowSummary`
- add a dashboard-specific repository
- introduce a generic analytics layer or app-wide dashboard framework

Use explicit dependency injection from `AppDependencies` through `RootView`.

## Data Sources

The dashboard should load:

- accounts from `AccountRepository`
- budgets from `BudgetRepository`
- goals from `GoalRepository`
- categories from `CategoryRepository`
- current-month transactions from `TransactionRepository.fetchTransactions(occurredFrom:occurredBefore:)`

Derived values should be computed by:

- `CalculateAccountBalance` per account
- `CalculateBudgetProgress` per budget
- `CalculateGoalProgress` per goal
- `CalculateCashFlowSummary` per currency for the dashboard cash-flow period

Dashboard code may group already-derived `Money` values by currency for presentation, but must not replace calculator formulas.

## Currency and Net Worth Policy

Cairn has no FX conversion.

The dashboard must not sum or relabel balances across currencies.

Account totals should be grouped per currency.

Show one "Net Worth" value only when the loaded account balances contain exactly one currency. If there are multiple currencies, show per-currency totals and explanatory native text that no single net worth is shown because Cairn does not convert currencies.

If there are no accounts, do not show a fake zero net worth. Show an empty account summary instead.

## Cash-Flow Period Semantics

Use a simple recent period:

```text
start of the current calendar month <= occurredAt < now
```

The dashboard store must receive:

- an explicit `Calendar`
- a focused date provider returning the current reference `Date`

Production may use the user's normal calendar/time-zone semantics via `Calendar.autoupdatingCurrent` at the composition boundary.

Tests must use a fixed calendar/time zone and fixed reference date.

Cash-flow summaries should be calculated for each currency represented by account balances. If no account currencies are available, cash flow cannot truthfully choose a summary currency and should be omitted with a clear empty-state message.

Do not use `Date.now` or `Calendar.current` inside reusable dashboard state.

## Account Summary

Show:

- each account name
- account type
- derived current balance
- per-currency totals
- single-currency net worth only when all included balances share one currency

Balance derivation must call `CalculateAccountBalance` per account.

Do not persist balance or net-worth state.

## Budget Summary

Show a concise budget status for each loaded budget:

- category identity
- limit
- spent
- remaining

Use `CalculateBudgetProgress`.

Do not add charts or custom progress visuals. Avoid `ProgressView` for overspending because clamping could misrepresent negative remaining values.

Unknown category ids should display as "Unknown Category" rather than blocking the dashboard.

## Goal Summary

Show a concise goal status for each loaded goal:

- name
- current amount
- target amount
- remaining amount
- completion state

Use `CalculateGoalProgress`.

Do not add projections, contribution history, or charts.

## Recent Transactions

Use `TransactionRepository.fetchTransactions(occurredFrom:occurredBefore:)` for the same current-month period.

Show a small deterministic list using repository ordering and a fixed presentation limit.

At minimum show:

- amount
- direction
- date
- account identity
- memo when present

If there are no current-month transactions, show an empty recent-activity state.

Do not add search, filters, pagination, or transaction drill-down in this milestone.

## State and Error Behavior

Use a clear loading/error/loaded model.

The dashboard should load into one coherent snapshot. If any required repository or calculation fails during the load, the whole dashboard load should fail and surface one dashboard error rather than showing partial values mixed with missing sections.

This keeps the first dashboard implementation simple and avoids silently replacing failed calculations with zero.

Empty repositories are valid and should produce an empty dashboard state, not an error.

## Concurrency

Repository calls are async.

Calculations are async or synchronous depending on their existing APIs.

Keep feature state `@MainActor` isolated.

Parallelize independent work only where simple and safe. Do not introduce custom task orchestration infrastructure.

## UI

Use native SwiftUI:

- `ScrollView`
- `VStack`
- `GroupBox`
- `LabeledContent`
- simple rows
- `ContentUnavailableView`

Do not add:

- custom chart systems
- bespoke design systems
- decorative animations
- gradients for style
- placeholder mock numbers

## Accessibility

Ensure:

- sections have clear headings
- financial summaries have meaningful labels
- inflow/outflow and positive/negative state are expressed as text, not color alone
- Dynamic Type is not obviously constrained

Full accessibility audit remains later.

## Testing

Use repository/calculation test doubles for feature/state tests.

Do not use SwiftData for dashboard state tests.

Cover at minimum:

Account summary:

- loads account balances
- preserves per-currency separation
- does not combine mixed currencies into fake net worth
- account balance failure surfaces

Cash flow:

- requested period is deterministic
- inflow/outflow/net summary is displayed from `CalculateCashFlowSummary`
- failure surfaces

Budgets:

- budget progress is derived
- multiple budgets display
- calculation failure surfaces

Goals:

- goal progress is derived
- completed and in-progress states are represented
- calculation failure surfaces

Recent transactions:

- ordering and limited presentation are deterministic

Loading/error:

- empty repositories produce a valid empty dashboard
- repository failure does not silently become fake zero data

Navigation:

- Dashboard remains the root Dashboard tab
- no feature-local navigation leaks into app-level routing

Do not duplicate unit tests for existing calculators.

## Scope

Do not add:

- FX conversion
- historical charts
- spending-by-category analytics
- forecasting
- credit score
- debt payoff logic
- notification summaries
- custom reporting engine
- dashboard customization
- widget support
- transaction drill-down

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- focused Dashboard feature tests
- existing focused calculator tests only if directly affected
- show `git status --short`
- show relevant diff

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

Do not stage or commit during implementation.

## Review Focus

- No SwiftData or `ModelContext` leakage into views.
- Explicit dependency injection through `AppDependencies`.
- Existing calculators are composed rather than reimplemented.
- No persisted derived dashboard state.
- No cross-currency summing or fake net worth.
- Deterministic current-month period in tests.
- Repository and calculation failures surface.
- Empty state is truthful and does not invent zeroes.
- Recent transactions use the existing bounded query.
- No speculative repository or analytics abstraction.

## Final Implementation

The Dashboard feature lives under `App/Cairn/Features/Dashboard/Presentation/`.

`DashboardView` is a native SwiftUI screen backed by `DashboardStore`, a focused `@MainActor @Observable` state owner. The view receives repositories and calculators through `RootView`; it does not instantiate repositories or access SwiftData.

`AppDependencies` now wires:

- account, budget, goal, category, and transaction repositories
- `CalculateAccountBalance`
- `CalculateBudgetProgress`
- `CalculateGoalProgress`
- `CalculateCashFlowSummary`
- a dashboard `Calendar` supplied at the composition boundary

`DashboardStore` builds one coherent snapshot containing account balances, per-currency totals, current-month cash flow, budget progress, goal progress, and a small current-month recent transaction list.

Currency behavior is intentionally conservative. Account balances are grouped by currency. A single net-worth value is shown only when all account balances share one currency. Mixed-currency accounts show per-currency totals and no fake aggregate.

Cash flow uses the deterministic period:

```text
start of current calendar month <= occurredAt < now
```

The store accepts an explicit calendar and date provider, so tests use fixed time semantics while production uses `Calendar.autoupdatingCurrent`.

Budget and goal sections derive progress through `CalculateBudgetProgress` and `CalculateGoalProgress`. Derived values are not persisted.

The dashboard treats repository or calculation failure as a whole-dashboard load failure. This avoids partial fake summaries and prevents failed calculations from being silently replaced with zero. Empty repositories remain a valid loaded state.

Recent transactions use the existing bounded transaction repository query and preserve repository ordering with a small presentation limit. No transaction drill-down was added.

Validation performed:

- `git -c core.fsmonitor=false diff --check`
- generic iOS Simulator build
- focused Dashboard feature tests
- affected app navigation shell tests

Deferred behavior:

- FX conversion
- historical charts
- spending analytics
- forecasting
- dashboard customization
- transaction drill-down
- partial per-section retry/error recovery
