# Milestone 31: Budget Progress Calculation

Status: in-progress

## Objective

Implement the authoritative derived progress calculation for a `Budget`.

Budget progress must be calculated from existing budgets and transactions without persisting derived state. The derived state should report the budget, exact spent amount, and exact remaining amount. A progress ratio should only be added if it can be represented clearly without binary floating-point monetary arithmetic, `NaN`, or infinity.

## Scope

- Add a focused finance workflow/calculator for deriving progress for one budget.
- Fetch the target `Budget` by `BudgetID`.
- Fail explicitly if the budget does not exist.
- Obtain the transactions needed to evaluate the budget using the existing `TransactionRepository` contract.
- Include only qualifying outflow transactions.
- Treat inflows as non-contributing.
- Match transactions by `Budget.categoryID`.
- Apply budget period containment using `startDate <= occurredAt < endDate` unless an existing domain definition establishes different semantics.
- Validate currency only for transactions that otherwise qualify.
- Calculate spent from zero in `Budget.limit.currencyCode`.
- Calculate `remaining = limit - spent` without clamping overspending.
- Add focused tests with lightweight in-memory repository test doubles.
- Update this milestone spec and the prompt README.

## Constraints

- Do not add `spent`, `remaining`, progress, or percentage to `Budget`.
- Do not persist or cache derived budget progress.
- Do not mutate or normalize transaction dates.
- Do not modify repository contracts unless current contracts make correct calculation impossible and the blocker is reported first.
- Do not import SwiftUI or SwiftData.
- Do not know about persistence records such as `BudgetRecord` or `TransactionRecord`.
- Do not use `Double` or `Float` for monetary arithmetic.
- Do not introduce binary floating-point monetary calculations, rounding, currency conversion, refund handling, budget rollover, recurring budget periods, notifications, alerts, category hierarchy, per-account budget allocation, forecasting, date-range repository optimization, presentation formatting, colors, or UI state.
- Do not introduce service locators, singleton repositories, SwiftUI `Environment` dependencies, generic financial-calculation frameworks, or unnecessary abstractions.
- Let repository, domain, and `Money` errors propagate naturally where appropriate.

## Affected Files

- `App/Cairn/Core/Finance/CalculateBudgetProgress.swift`
- `App/CairnTests/Core/Finance/CalculateBudgetProgressTests.swift`
- `Documentation/prompts/31-budget-progress.md`
- `Documentation/prompts/README.md`

## Key Design Decisions

- Place the calculator in `Core/Finance` because it composes shared finance domain types and repository contracts and is expected to become the authoritative calculation later used by Budgets UI and Dashboard.
- Use constructor injection for `BudgetRepository` and `TransactionRepository`.
- Use a small typed application error for application-specific failures: `budgetNotFound` and `transactionCurrencyMismatch`.
- Return a small immutable derived value containing at least `budget`, `spent`, and `remaining`.
- Omit progress ratio unless the implementation has a clear Decimal-based representation with deterministic zero-limit behavior and no `NaN` or infinity output.
- Use `Budget.limit.currencyCode` as the currency for zero spent and remaining.
- Reuse `Money.adding(_:)` and `Money.subtracting(_:)` for Decimal-preserving arithmetic and matching-currency enforcement.
- Use `startDate <= occurredAt < endDate` for period containment if no existing domain helper defines containment.
- Validate currency only after direction, category, and period qualification.
- Do not sort transactions because aggregation should be independent of transaction ordering.

## Prerequisite Status

Milestone 31a resolves the category-assignment/query blocker by adding optional `Transaction.categoryID` and `TransactionRepository.fetchTransactions(categoryID:)`.

Milestone 31 itself remains in progress and unimplemented until the budget-progress calculator and focused tests are added against that prerequisite capability.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run focused budget-progress tests on a concrete available iPhone simulator.
- Run `BudgetTests`.
- Run `TransactionTests`.
- Run `MoneyTests`.
- Run `/review` focused on the review areas below.
- Show `git status --short`.
- Show the complete relevant diff.

## Review Focus

- Budget period boundary correctness.
- Qualifying-transaction filtering.
- Inflow treatment.
- Category matching.
- Currency validation occurring only after qualification.
- Decimal correctness.
- Overspending behavior.
- Zero-limit behavior.
- No persisted derived state.
- Repository error propagation.
- No SwiftData or UI leakage.
- Unnecessary abstraction.
- Suitability as the calculation used later by Budgets UI and Dashboard.

## Commit Intent

Commit the budget-progress calculator, focused tests, completed milestone documentation, and prompt README update after the domain/repository blocker is resolved and validation passes.
