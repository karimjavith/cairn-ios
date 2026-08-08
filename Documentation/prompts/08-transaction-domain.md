# 08 Transaction Domain

Status: completed

## Objective

Create the `Transaction` domain model for dated account inflows and outflows.

## Scope

- Add `TransactionID`, `TransactionDirection`, and `Transaction`.
- Link transactions to `AccountID`.
- Store amount, date, and optional memo.
- Normalize memo text.

## Constraints

- Do not add persistence implementation.
- Do not permit negative transaction amounts.
- Keep domain independent of SwiftUI and SwiftData.

## Required Files or Areas

- `App/Cairn/Core/Finance/Transaction.swift`
- `App/CairnTests/Core/Finance/TransactionTests.swift`

## Key Design Decisions

- Transaction amounts are non-negative `Money` values.
- Direction determines inflow or outflow instead of signed amounts.
- Empty or whitespace-only memos normalize to `nil`.

## Validation Requirements

- Tests cover direction, amount validation, memo normalization, Codable behavior, equality/hashability, and Sendable.

## Review Focus

- Correct amount semantics.
- Account identity preservation.
- Domain-only implementation.

## Commit Intent

Commit the transaction domain model and tests.
