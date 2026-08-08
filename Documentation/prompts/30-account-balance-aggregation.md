# Milestone 30: Account Balance Aggregation

Status: completed

## Objective

Implement the authoritative current-balance calculation for an `Account`.

The derived balance must equal:

```text
opening balance + transaction inflows - transaction outflows
```

The balance must be returned as `Money` and must not be persisted.

## Scope

- Add a focused finance workflow/calculator for deriving the current balance of one account.
- Fetch the target `Account` by `AccountID`.
- Fail explicitly if the account does not exist.
- Fetch transactions for the same `AccountID`.
- Aggregate from `Account.openingBalance`.
- Add inflow amounts and subtract outflow amounts.
- Validate that every transaction amount currency matches the account opening-balance currency.
- Add focused tests with lightweight in-memory repository test doubles.
- Update this milestone spec and the prompt README.

## Constraints

- Do not add `currentBalance` to `Account`.
- Do not persist or cache the derived balance.
- Do not mutate `Account.openingBalance`.
- Do not modify repository contracts.
- Do not import SwiftUI or SwiftData.
- Do not know about persistence records such as `AccountRecord` or `TransactionRecord`.
- Do not use `Double` or `Float` math.
- Do not introduce rounding, currency conversion, overdraft rules, date filtering, transfer handling, cleared/pending state, limits, cash-flow summaries, net-worth calculations, or dashboard logic.
- Do not introduce service locators, singleton repositories, SwiftUI `Environment` dependencies, generic services, or unnecessary abstractions.
- Let repository and `Money` errors propagate naturally where appropriate.

## Affected Files

- `App/Cairn/Core/Finance/CalculateAccountBalance.swift`
- `App/CairnTests/Core/Finance/CalculateAccountBalanceTests.swift`
- `Documentation/prompts/30-account-balance-aggregation.md`
- `Documentation/prompts/README.md`

## Key Design Decisions

- Place the calculator in `Core/Finance` because it composes shared finance domain types and repository contracts and is expected to become a reusable building block for dashboard, net-worth, and cash-flow work.
- Use constructor injection for `AccountRepository` and `TransactionRepository`.
- Use a small typed application error for application-specific failures: `accountNotFound` and `transactionCurrencyMismatch`.
- Compare transaction currencies against `Account.openingBalance.currencyCode`, which is the currency of the starting balance and is already normalized by the domain.
- Reuse `Money.adding(_:)` and `Money.subtracting(_:)` for Decimal-preserving arithmetic and matching-currency enforcement.
- Do not sort transactions because addition and subtraction produce the same balance regardless of transaction ordering.
- Keep the calculator independent of `MainActor`.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run focused account-balance tests on a concrete available iPhone simulator.
- Run `MoneyTests`.
- Run `AccountTests`.
- Run `TransactionTests`.
- Run `/review` focused on the review areas below.
- Show `git status --short`.
- Show the complete relevant diff.

## Review Focus

- Authoritative balance formula correctness.
- No persisted derived state.
- `Money` and `Decimal` correctness.
- Currency mismatch handling.
- Repository error propagation.
- Transaction ordering independence.
- Explicit dependency injection.
- No SwiftData or UI leakage.
- Unnecessary abstraction.
- Suitability as a building block for dashboard, net-worth, and cash-flow work.

## Commit Intent

Commit the account-balance calculator, focused tests, completed milestone documentation, and prompt README update.
