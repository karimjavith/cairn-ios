# Milestone 49: Performance / Concurrency Audit

Status: completed

## Objective

Audit Cairn for real performance, actor-isolation, task-lifetime, and unnecessary-work issues.

Do not optimize speculatively. Production changes should be made only when the audit identifies concrete impact on correctness, concurrency safety, user-visible latency, repeated work, query efficiency, or meaningful regression coverage.

## Audit Scope

Inspect:

- `AppDependencies`
- app startup and bootstrap
- all feature stores
- SwiftData repositories
- application workflows and calculators
- Dashboard composition
- recurring scheduling
- seed loader and bootstrap
- SwiftUI `.task` usage
- list, detail, and editor loading patterns

## Constraints

- Audit before modifying production code.
- Fix only issues with concrete impact.
- Do not refactor for theoretical speed.
- Do not introduce caching frameworks.
- Do not introduce generic async abstractions.
- Do not create background actors without need.
- Do not change domain semantics.
- Do not weaken `Sendable`.
- Do not move presentation state off `MainActor` incorrectly.
- Do not add production logging noise.
- Do not add a benchmarking framework.
- Do not build generic query infrastructure.
- Do not broaden repository contracts casually.
- Do not run `/review`.
- Do not stage or commit.

## Audit Method

Produce findings categorized as:

- correctness/concurrency issue
- actor-isolation issue
- task-lifetime/cancellation issue
- duplicate/redundant work
- main-thread performance issue
- repository/query inefficiency
- memory/lifetime issue
- meaningful test gap
- harmless implementation difference

When duplicate loads or repeated calculations are harmless at current app scale, document them rather than over-engineering.

## Concurrency Review

Verify:

- SwiftData repositories remain safely isolated.
- `ModelContext` does not cross actors.
- `Sendable` contracts remain sound.
- `MainActor` is used only for presentation state.
- Pure calculators remain non-`MainActor`.
- Async repository calls are awaited correctly.
- No detached tasks introduce unsafe state access.
- Task cancellation does not leave stale UI state.

## Feature Store Review

Audit:

- repeated `.task` execution
- duplicate loads after navigation
- overlapping refreshes
- stale async result overwriting newer state
- editor save/delete tasks
- mutation followed by reload patterns

Do not introduce a generic task manager.

## Dashboard Review

Audit for:

- serial execution of independent repository or calculation work that causes unnecessary latency
- duplicate fetching of the same data
- repeated calculation of identical values
- unbounded transaction queries
- mixed actor hops

Parallelize only independent work where it is simple and demonstrably safe.

Do not add caching unless there is a concrete repeated-work problem.

## Persistence Review

Audit repository queries for:

- accidental fetch-all when bounded or scoped query exists
- in-memory filtering that should reasonably happen in SwiftData
- repeated fetches inside loops
- N+1-style patterns
- unbounded result sets

Do not change deterministic ordering semantics.

## Account Balance, Budget, and Dashboard Review

Specifically inspect whether feature or dashboard list rendering causes per-row repository queries.

If account balance or budget progress produces obvious N+1 behavior:

- identify it
- fix only if the smallest architectural change is clear
- stop and report the blocker if fixing requires a broader aggregate query/API

Do not add speculative cache layers.

## Recurring Scheduling Review

Verify occurrence generation:

- remains bounded
- does not perform arbitrarily large naive iteration for normal UI usage
- does not introduce seconds-based recurrence logic
- has no accidental infinite loop

## Seed Bootstrap Review

Verify:

- bootstrap runs once
- duplicated imports do not occur
- normal startup path has negligible overhead when seeding is disabled
- unnecessary work does not happen on `MainActor`

## Memory and Lifetime Review

Check:

- closures do not unnecessarily retain feature stores
- long-lived tasks are not orphaned
- large fetched model arrays are not retained accidentally
- no singleton or global state has appeared

## Performance Measurement

Do not add a benchmarking framework.

Where a suspected issue is measurable with a focused test or signpost-like observation, use the smallest practical validation.

Do not add production logging noise.

## Testing Plan

Add focused regression tests only for real fixes.

Prioritize:

- stale async result protection
- duplicate operation prevention
- cancellation behavior
- one-shot bootstrap
- bounded query behavior

Do not add performance tests with brittle wall-clock thresholds.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused tests for every changed area
4. full `CairnTests` target if concurrency changes are broad enough to justify it

## Review Focus

- Concurrency changes are correctness-oriented and scoped.
- SwiftData access remains actor-isolated.
- Domain/application calculators do not become presentation-bound.
- UI stores stay `MainActor` presentation state owners.
- Repository queries remain deterministic and no broader contracts are introduced without explicit need.
- Dashboard and feature loading avoid concrete unnecessary work without speculative caching.
- Recurring scheduling remains bounded.
- Seed bootstrap remains one-shot and cheap when disabled.

## Final Documentation Requirements

After implementation, update this file with an `Audit Findings` section covering:

- issues found
- fixes made
- deliberately unchanged performance differences
- known limitations or deferred optimizations

Set status to `completed`.

Update `Documentation/prompts/README.md` consistently.

## Audit Findings

### Correctness/Concurrency Issue

- No unsafe detached task usage found.
- No `ModelContext` crossing presentation or domain boundaries found.
- No broad stale-result bug was fixed during the initial pass because the current SwiftUI `.task` usage performs initial loading and retry from feature-owned stores. Overlapping manual loads are possible in tests or future UI, but fixing every store would require a cross-feature state pattern that is not justified by current UI behavior.

### Actor-Isolation Issue

- SwiftData repositories remain `@ModelActor` isolated and keep `modelContext` private.
- Feature stores and editor states remain `@MainActor` presentation state owners.
- Pure finance workflows and domain value types remain non-`MainActor` and `Sendable` where appropriate.

### Task-Lifetime/Cancellation Issue

- SwiftUI views use `.task` for initial loads and explicit `Task { ... }` for button-triggered retry/save/delete actions.
- No long-lived orphaned task or detached task was found.
- Store methods do not explicitly check `Task.isCancelled`; this is a harmless current difference because loads are short, repository calls are awaited, and there is no streaming or long-running loop in presentation state.

### Duplicate/Redundant Work

- Dashboard performs independent initial repository reads serially: accounts, budgets, goals, categories, and current-period transactions. This has concrete latency impact and can be safely parallelized without changing contracts or snapshot semantics.
- Dashboard also loads cash-flow summaries and budget progress serially after account balances are available even though those two operations are independent. This has concrete latency impact and can be safely overlapped.
- Dashboard account balances and budget progress are calculated per item. This creates N+1-style repository calls through existing calculator contracts, but fixing it cleanly would require broader aggregate APIs or cache layers and is deferred.
- Budget and Dashboard budget progress calculation refetches each budget by ID even when a loaded budget is already available. This is contract-driven by `CalculateBudgetProgress(budgetID:)` and was not changed.
- Cash-flow summaries fetch the same bounded transaction range once per currency through `CalculateCashFlowSummary`. Avoiding this would require a multi-currency summary API or duplicating calculation logic in Dashboard, so it was not changed.

### Main-Thread Performance Issue

- No large synchronous persistence or parsing work was found on `MainActor` in the normal production startup path.
- Dashboard does composition on `MainActor`, but the expensive work is awaited repository/calculator calls and small value transformations.

### Repository/Query Inefficiency

- Transactions list intentionally fetches all transactions via the existing bounded date query using `.distantPast` to `.distantFuture`. This is unbounded in practice but matches the current all-transactions screen and existing repository surface.
- Category deletion checks all budgets to detect references because there is no category-scoped budget query. This is not changed to avoid broadening repository contracts for a rare destructive path.
- Seed bootstrap checks store emptiness by fetching all records, including all transactions. This is DEBUG-only, opt-in, and runs only when local seed loading is requested.
- Goal and Recurring Transaction repositories sort mapped domain values in memory. This remains intentional due to optional-date ordering concerns documented by the persistence audit.

### Memory/Lifetime Issue

- No singleton or global mutable state found.
- App composition keeps repositories and calculators in `AppDependencies`; feature stores own only presentation state.
- No large fetched model arrays are retained beyond feature state that backs visible UI.

### Meaningful Test Gap

- Existing Dashboard tests cover output ordering and failure behavior, but not parallel startup latency because wall-clock performance tests would be brittle.
- Focused Dashboard tests should be run after the implementation to verify snapshot semantics remain unchanged.

### Harmless Implementation Difference

- Mutation flows save or delete and then reload their feature data. This duplicates some work but preserves simple, truthful state and is acceptable at current scale.
- Feature stores use straightforward sequential loads where the data volume is small or dependency order is meaningful.

## Fixes Made

- Updated `DashboardStore.loadDashboard()` to start independent repository reads concurrently:
  - accounts
  - budgets
  - goals
  - categories
  - current-period transactions
- Updated `DashboardStore.loadDashboard()` to overlap cash-flow summary loading with budget-progress loading after account balances and currency totals are known.
- Preserved existing snapshot shape, deterministic output ordering, error behavior, repository contracts, and calculator contracts.

## Deliberately Unchanged Performance Differences

- Account balance loading remains per account through `CalculateAccountBalance(accountID:)`.
- Budget progress loading remains per budget through `CalculateBudgetProgress(budgetID:)`.
- Cash-flow summaries remain per currency through `CalculateCashFlowSummary(start:end:currencyCode:)`.
- Transactions list still loads all transactions through the existing bounded date API because the current screen is an all-transactions list.
- Category deletion still fetches budgets to check references because a category-scoped budget query does not exist.
- Seed bootstrap still checks whether all stores are empty through existing repository APIs; this is DEBUG-only and opt-in.
- Store mutation flows still reload after save/delete to keep state simple and truthful.

## Known Limitations and Deferred Optimizations

- A broader aggregate account-balance API could reduce N+1 account balance work, but that would be a repository/workflow contract change and was outside this audit fix.
- A budget-progress API that accepts already-loaded budgets or calculates multiple budgets together could avoid refetching budgets, but that should be designed explicitly rather than patched into Dashboard.
- A multi-currency cash-flow summary API could avoid fetching the same bounded transaction range once per currency.
- SwiftUI accessibility/performance and large-list behavior should be revisited when real production-scale datasets exist.
