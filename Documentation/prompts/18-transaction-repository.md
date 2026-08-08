# 18 Transaction Repository

Status: completed

## Objective

Implement the SwiftData-backed `TransactionRepository` using the existing `TransactionRecord` mapping boundary.

## Scope

- Add an actor-backed SwiftData repository.
- Implement account-scoped fetch, fetch by transaction ID, save, and delete.
- Preserve mapping through `TransactionRecord`.

## Constraints

- Do not expose SwiftData records or contexts.
- Do not create generic repository abstractions.
- Keep transaction fetches scoped to account ID.

## Required Files or Areas

- `App/Cairn/Persistence/Transactions/SwiftDataTransactionRepository.swift`
- `App/CairnTests/Persistence/Transactions/SwiftDataTransactionRepositoryTests.swift`

## Key Design Decisions

- Repository uses `@ModelActor`.
- Account-scoped fetch is sorted by occurred date descending and ID.
- Save updates existing records by ID or inserts a new record.
- Delete is idempotent for missing transactions.

## Validation Requirements

- Tests cover scoped fetches, deterministic ordering, fetch by ID, insert, update, delete, and missing delete.
- Generic iOS Simulator build passes.

## Review Focus

- Account filtering correctness.
- Actor-backed SwiftData usage.
- Domain-only API and no abstraction creep.

## Commit Intent

Commit the SwiftData Transaction repository and tests.
