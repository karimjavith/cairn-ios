# 12 Recurring Transaction Domain

Status: completed

## Objective

Create the `RecurringTransaction` domain model for scheduled account inflows and outflows.

## Scope

- Add `RecurringTransactionID`, `RecurrenceFrequency`, and `RecurringTransaction`.
- Store account identity, direction, amount, frequency, start date, optional end date, and optional memo.
- Validate amount and date range.

## Constraints

- Do not implement scheduling, notifications, or persistence.
- Do not permit negative amounts.
- Keep recurrence rules simple and domain-local.

## Required Files or Areas

- `App/Cairn/Core/Finance/RecurringTransaction.swift`
- `App/CairnTests/Core/Finance/RecurringTransactionTests.swift`

## Key Design Decisions

- Frequency is limited to daily, weekly, monthly, and yearly.
- Optional end date must be after start date.
- Memo normalization matches transaction memo behavior.

## Validation Requirements

- Tests cover recurrence values, amount/date validation, memo normalization, Codable behavior, equality/hashability, and Sendable.

## Review Focus

- Date-range invariant.
- Consistency with `Transaction`.
- No scheduler or persistence leakage.

## Commit Intent

Commit the recurring transaction domain model and tests.
