# 15 Account Persistence Model

Status: completed

## Objective

Create the SwiftData persistence model and mapping boundary for `Account`.

## Scope

- Add `AccountRecord` as a SwiftData `@Model`.
- Persist only values required to reconstruct `Account`.
- Add explicit mapping between `Account` and `AccountRecord`.
- Register the record in the centralized schema.

## Constraints

- Do not implement the repository in this milestone.
- Do not persist `Money` directly.
- Preserve `AccountID` across round trips.
- Keep domain independent of SwiftData.

## Required Files or Areas

- `App/Cairn/Persistence/Accounts/AccountRecord.swift`
- `App/CairnTests/Persistence/Accounts/AccountRecordTests.swift`
- `App/Cairn/App/CairnApp.swift`

## Key Design Decisions

- IDs persist as `UUID`.
- Account type persists as a stable string.
- Opening balance amount persists as a string to preserve Decimal precision.
- Mapping back reconstructs through `Money` and `Account` validation.

## Validation Requirements

- Tests cover mapping, ID preservation, Decimal precision, currency preservation, invalid type, invalid amount, domain validation, and in-memory SwiftData round trip.
- Generic iOS Simulator build passes.

## Review Focus

- SwiftData iOS 17 compatibility.
- Decimal precision.
- Domain/persistence separation.
- Minimal mapping error design.

## Commit Intent

Commit Account SwiftData record, mapping tests, and schema registration.
