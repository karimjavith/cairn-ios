# Milestone 34: Cash-Flow Summary

Status: completed

## Objective

Implement an authoritative bounded-period cash-flow summary derived from existing `Transaction` domain values.

The summary should calculate:

- total inflows
- total outflows
- net cash flow

for a requested finite date interval.

## Scope

- Add a focused finance calculator for cash-flow summaries when the transaction repository contract can provide the required transaction set.
- Return a small immutable `CashFlowSummary` value.
- Include the summarized period, `totalInflows`, `totalOutflows`, and `netCashFlow`.
- Derive all values from transactions at calculation time.
- Add focused core finance tests with lightweight in-memory repository test doubles.

## Constraints

- Do not persist summary state.
- Do not modify `Transaction` to store derived financial state.
- Do not import SwiftData or SwiftUI.
- Do not know about persistence records such as `TransactionRecord`.
- Do not implement UI formatting, chart points, colors, labels, reports, export, forecasts, recurring projections, account balances, budget calculations, spending by category, or net worth.
- Do not use `Double`, `Float`, binary floating-point monetary calculations, rounding, or currency conversion.
- Do not introduce service locators, singleton repositories, SwiftUI `Environment` dependencies, generic analytics frameworks, or generic query frameworks.
- Do not work around missing aggregate transaction access by fetching arbitrary known accounts or coupling calculation code to persistence.

## Affected Files

- `App/Cairn/Core/Finance/CalculateCashFlowSummary.swift`
- `App/CairnTests/Core/Finance/CalculateCashFlowSummaryTests.swift`
- `Documentation/prompts/34-cash-flow-summary.md`
- `Documentation/prompts/README.md`

Milestone 34A resolved the repository blocker by adding the required bounded cross-account transaction query:

```swift
fetchTransactions(occurredFrom:occurredBefore:)
```

## Key Design Decisions

- Place the calculator in `Core/Finance` because it composes shared finance domain types and repository contracts and is expected to become a reusable building block for dashboard and summary features.
- Use constructor injection for the required repository dependency.
- Prefer depending only on `TransactionRepository`.
- Keep the returned summary immutable and free of presentation concerns.
- Use `Money.adding(_:)` and `Money.subtracting(_:)` for Decimal-preserving arithmetic.
- Do not sort transactions because aggregation must be independent of transaction ordering.
- Let repository failures propagate unchanged where practical.
- Introduce `CashFlowSummaryPeriod` as the smallest focused finite-period representation for this calculator.
- Reject invalid periods before calling the repository.
- Rely on the repository date query as the period boundary and avoid redundant production date filtering.
- Filter by the caller-supplied summary currency in the calculator because global cash-flow input may legitimately include transactions from several currencies.

## Period Semantics

- The requested period must be finite.
- Both `start` and `end` must be finite `Date` values; infinite boundaries are invalid.
- The period uses `start <= occurredAt < end`.
- The start boundary is inclusive.
- The end boundary is exclusive.
- A transaction exactly at `start` contributes.
- A transaction exactly at `end` does not contribute.
- Invalid or non-positive periods must fail explicitly rather than being silently repaired.
- Use an existing focused date-range domain type only if its semantics already match these requirements.
- Otherwise introduce only the smallest representation required for this calculation.

## Currency Semantics

- Cairn does not yet perform currency conversion.
- The caller supplies the currency being summarized.
- Inflow and outflow totals start as zero `Money` in the requested summary currency.
- Only transactions whose `Money.currencyCode` matches the requested summary currency contribute.
- Transactions in other currencies are excluded rather than converted.
- Different currencies must never be added together, treated as equivalent, or silently relabeled.
- `netCashFlow = totalInflows - totalOutflows`.
- Negative net cash flow is valid and must not be clamped.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `CalculateCashFlowSummaryTests` on a concrete available iPhone simulator
- `TransactionTests`
- `MoneyTests`

Focused tests must cover:

- empty transaction sets
- single and multiple inflows
- single and multiple outflows
- mixed inflows and outflows
- positive, zero, and negative net cash flow
- period boundaries before start, exactly at start, inside range, exactly at end, and after end
- requested-currency inclusion
- different-currency exclusion
- mixed-currency input never combining currencies
- returned `Money` values using the requested currency
- high-precision Decimal values remaining exact
- transaction-order independence
- category, account ID, and memo not altering qualification
- repository failure propagation
- explicit invalid-period failure if invalid period construction is possible

## Review Focus

- Repository contract correctness for obtaining all transactions required by the summary.
- Period boundary correctness.
- Currency filtering and absence of currency conversion.
- Money and Decimal correctness.
- Repository error propagation.
- No persisted derived state.
- No SwiftData, SwiftUI, persistence-record, or formatting leakage.
- No speculative repository broadening.
- No unnecessary abstraction.

## Commit Intent

Commit the focused cash-flow summary calculator, tests, completed milestone documentation, and prompt README update once the repository contract supports the required cross-account transaction set.
