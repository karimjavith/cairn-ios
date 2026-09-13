# Milestone 55: Accounts + Transactions Redesign

Status: in-progress

## Objective

Redesign the Accounts and Transactions feature surfaces to match the approved Cairn visual system established by the Dashboard redesign.

This milestone applies the existing product language without changing finance domain models, repository contracts, persistence architecture, or business rules.

## Product Direction

Accounts and Transactions must feel consistent with Dashboard:

- warm Cairn canvas in light mode
- deep plum-black canvas in dark mode
- plum/lavender brand hierarchy
- 24-point primary page grid
- compact, breathable financial information density
- flat composition by default
- native SwiftUI navigation, forms, sheets, controls, tab bar, and SF Symbols
- semantic green/red only for financial meaning

Avoid glass effects, heavy shadows, custom tab bars, oversized per-row cards, and generic stock empty-state presentation.

## Accounts

### List

Accounts uses a scrollable Cairn canvas layout.

Single-currency accounts show:

- eyebrow: `Total balance`
- dominant formatted total balance
- context such as `3 accounts in GBP`

Mixed-currency accounts show:

- heading: `Balances`
- compact per-currency rows
- explanatory text: `Cairn does not convert currencies.`

Mixed currencies must never be summed or converted.

Rows show account name, account type, and current balance. Balances remain visually neutral by default; negative balances keep the minus sign but are not universally red.

### Empty

Use Cairn empty-state composition:

- title: `Your accounts, in one place.`
- body: `Add your first account to start tracking balances and activity.`
- primary action: `Add account`

The action uses the existing account creation flow.

### Detail And Editor

Account detail leads with account identity and dominant current balance, then compact account/balance details.

Account creation and editing keep native sheet/form behavior with name, type, opening amount, and currency fields. Validation semantics remain unchanged.

Delete and blocked-delete behavior remain intact.

## Transactions

### List

Transactions uses a scrollable Cairn canvas layout without a large marketing hero.

Transactions are grouped chronologically by day with headers such as:

- `Today`
- `Yesterday`
- localized dates such as `12 Sep 2026`

Ordering remains deterministic: occurred date descending, then transaction ID.

Rows use customer-facing language:

- `Income`
- `Expense`

Rows show category/memo context, account, signed formatted amount, and useful time metadata. Color reinforces direction but is never the only semantic carrier.

No sorting, filtering, or search controls are added in this milestone.

### Empty

When accounts exist but there are no transactions:

- title: `No transactions yet`
- body: `Add your first transaction to start building your activity history.`
- primary action: `Add transaction`

When there are no accounts:

- title: `Add an account first`
- body: `Transactions need an account before they can be recorded.`
- primary action: `Add account`

The zero-account action reuses the existing app-owned Add Account routing.

### Detail And Editor

Transaction detail leads with Income/Expense, dominant signed amount, date/time, and account context before compact details.

Transaction creation and editing keep native sheet/form behavior with account, Income/Expense direction, amount, date, category, and memo fields. Internally this still maps to inflow/outflow domain values.

Delete behavior and confirmation remain unchanged.

## Testing

Focused tests cover:

- single-currency account summary
- mixed-currency account summary without fake totals
- account empty-state creation wiring
- Income/Expense presentation mapping
- transaction day grouping
- deterministic ordering within grouped days
- zero-account transaction guard
- empty transaction state creation wiring

No pixel, snapshot, or screenshot-only test infrastructure is introduced.

## Validation

Before handoff, run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator Debug build
3. focused Accounts store tests
4. focused Transactions store tests
5. `AppNavigationShellTests`

Do not run `/review`, stage, or commit.

## Acceptance Gate

Milestone 55 remains `in-progress` until engineering validation passes and product-owner visual approval is granted from simulator review.
