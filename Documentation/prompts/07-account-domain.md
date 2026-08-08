# 07 Account Domain

Status: completed

## Objective

Create the `Account` domain model and identity/type values for user financial accounts.

## Scope

- Add `AccountID`, `AccountType`, and `Account`.
- Validate account names.
- Normalize account currency through `Money`.
- Ensure opening balance currency matches account currency.

## Constraints

- Do not add persistence implementation.
- Do not expose SwiftData or SwiftUI in the domain.
- Keep validation explicit and typed.

## Required Files or Areas

- `App/Cairn/Core/Finance/Account.swift`
- `App/CairnTests/Core/Finance/AccountTests.swift`

## Key Design Decisions

- IDs wrap `UUID`.
- Names are trimmed and empty names are rejected.
- Account currency is normalized and must match opening balance currency.

## Validation Requirements

- Tests cover stored values, validation errors, equality/hashability, Codable identity, and Sendable expectations.

## Review Focus

- Domain invariants.
- Currency consistency.
- No persistence-domain coupling.

## Commit Intent

Commit the account domain model and focused tests.
