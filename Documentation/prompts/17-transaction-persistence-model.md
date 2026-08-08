# 17 Transaction Persistence Model

Status: completed

## Objective

Create the SwiftData persistence model and mapping boundary for `Transaction`.

## Scope

- Add `TransactionRecord` as a SwiftData `@Model`.
- Persist transaction ID, account ID, direction, amount, currency, occurrence date, and optional memo.
- Add explicit mapping between `Transaction` and `TransactionRecord`.
- Register the record in the centralized schema.

## Constraints

- Do not implement the repository in this milestone.
- Do not persist `Money` directly.
- Preserve `TransactionID` and `AccountID`.
- Keep domain independent of SwiftData.

## Required Files or Areas

- `App/Cairn/Persistence/Transactions/TransactionRecord.swift`
- `App/CairnTests/Persistence/Transactions/TransactionRecordTests.swift`
- `App/Cairn/App/CairnApp.swift`

## Key Design Decisions

- IDs persist as `UUID`.
- Direction persists as a stable string.
- Amount persists as a Decimal string.
- Mapping back reconstructs through `Money` and `Transaction` validation.

## Validation Requirements

- Tests cover ID/account preservation, direction mapping, Decimal precision, currency, dates, memo normalization, invalid direction, invalid amount, negative amount validation, and in-memory SwiftData round trip.
- Generic iOS Simulator build passes.

## Review Focus

- Decimal precision and identifier preservation.
- Transaction invariant enforcement.
- No domain leakage from persistence.

## Commit Intent

Commit Transaction SwiftData record, mapping tests, and schema registration.
