# Milestone 35: Application Workflow Consistency Audit

Status: completed

## Objective

Audit Cairn's current application-layer finance workflows and calculators for consistency where consistency affects correctness, architecture, error semantics, concurrency, money handling, date boundaries, derived state, repository usage, and meaningful regression coverage.

The audit must review existing behavior before any production code changes are made. Production changes should be made only for justified issues that represent correctness risk, business-rule inconsistency, boundary violation, hidden persistence or UI coupling, unsafe concurrency or isolation, or meaningful missing regression coverage.

## Audit Scope

Review these workflows and calculators together:

- `CreateTransaction`
- `CalculateAccountBalance`
- `CalculateBudgetProgress`
- `CalculateGoalProgress`
- `RecurringTransactionSchedule`
- `CalculateCashFlowSummary`

Also inspect their repository dependencies, domain types, and focused tests.

Persistence internals are out of scope except where needed to verify application-layer boundaries and repository contracts.

## Constraints

- Do not review persistence internals beyond boundary verification.
- Do not modify code merely for stylistic uniformity.
- Do not force identical behavior where business semantics intentionally differ.
- Do not introduce a generic application error framework merely for consistency.
- Do not introduce new repository methods unless a real correctness blocker is discovered.
- Do not add new product behavior.
- Do not persist derived values such as account balances, budget progress, goal progress, cash-flow totals, or next recurring occurrences.
- Do not introduce SwiftData, SwiftUI, service locators, globals, singleton repository access, broad architectural changes, or custom concurrency infrastructure into application workflows.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run focused tests for all six application workflows and calculators.
- Run relevant domain regression suites.
- Run the full `CairnTests` target if practical.
- Show `git status --short`.
- Show the complete relevant diff.

Do not run `/review` as part of this milestone.

## Review Focus

- Application-layer boundaries: no SwiftData or SwiftUI imports, no persistence model knowledge, explicit dependencies, no service locators or globals.
- Concurrency: async repository-backed workflows, synchronous pure calculators, no `MainActor` leakage, reasonable `Sendable` usage, no unnecessary actors or infrastructure.
- Error semantics: explicit missing aggregate and currency mismatch errors, repository error propagation, domain-owned domain errors, safe duplicate creation semantics.
- Money and Decimal semantics: no `Double` or `Float` monetary arithmetic, reuse of `Money`, no silent currency conversion, intentional currency mismatch behavior.
- Date and boundary semantics: budget and cash-flow half-open periods, recurring strict-after next occurrence, exclusive configured end date, explicit bounded ranges, deterministic calendar and time-zone behavior.
- Derived state: no persisted or mutable domain storage for derived balances, progress, summaries, or next occurrences.
- Repository usage: smallest needed repository surface, no accidental broad fetches, no unnecessary dependencies, no misplaced application logic.
- Workflow-specific behavior for transaction creation, account balance, budget progress, goal progress, recurring scheduling, and cash-flow summary.
- Test consistency: meaningful gaps around accidental writes, currency mixing, date boundaries, duplicate creation, partial results on error, order dependence, invalid periods, and hidden persistence dependency.

## Audit Findings

### Issues Found

- Correctness issue: none found in the audited production workflows.
- Architectural inconsistency: none found. The audited workflows and calculators do not import SwiftData or SwiftUI, do not know persistence records, and use explicit dependencies.
- Error-semantics inconsistency: none found in production behavior. Missing aggregate errors are explicit where repository-backed workflows fetch a single aggregate; currency mismatch errors are explicit where cross-aggregate validation requires them; repository errors propagate unchanged; domain errors remain domain-owned.
- Concurrency/isolation issue: none found. Repository-backed workflows are `async throws`, pure calculators and scheduling remain synchronous, `MainActor` does not leak into finance logic, and no unnecessary actors or custom concurrency infrastructure were introduced.
- Meaningful test gap: recurring scheduling had strong boundary coverage but did not directly assert empty bounded occurrence ranges. A focused regression test was added.
- Harmless implementation difference: budget progress fetches transactions by category and applies direction, period, and currency qualification in the workflow, while cash-flow summary uses the bounded cross-account transaction query and filters by requested currency. This reflects different business semantics and current repository contracts.

### Fixes Made

- Added a focused recurring-schedule regression test covering an empty bounded occurrence range returning no occurrences.
- No production code changes were made because the audit did not identify a justified production issue.

### Intentionally Unchanged Differences

- Cash-flow summary continues to filter transactions to the explicitly requested currency instead of treating other currencies as errors.
- Budget progress continues to reject mismatched currency only after a transaction otherwise qualifies for the budget.
- Account balance continues to reject any transaction currency mismatch for the target account.
- Goal progress continues to rely on `Goal` currency invariants instead of adding application-level currency checks.
- Recurring scheduling continues to use injected `Calendar` semantics rather than matching budget or cash-flow date-period behavior.
- Repository contracts were not broadened for symmetry; no new repository methods were needed for correctness.
- Derived values remain unpersisted and are calculated on demand.

## Commit Intent

Commit a focused application workflow consistency audit result, any justified production fixes, focused regression tests, and milestone documentation updates after manual review. Do not stage or commit during implementation.
