# 16 Account Repository

Status: completed

## Objective

Implement the SwiftData-backed `AccountRepository` using the existing `AccountRecord` mapping boundary.

## Scope

- Add an actor-backed SwiftData repository.
- Implement fetch all, fetch by ID, save, and delete.
- Preserve domain mapping and validation at the persistence boundary.

## Constraints

- Do not expose SwiftData records to callers.
- Do not create generic repository infrastructure.
- Do not bypass `AccountRecord` mapping.
- Keep save behavior deterministic for inserts and updates.

## Required Files or Areas

- `App/Cairn/Persistence/Accounts/SwiftDataAccountRepository.swift`
- `App/CairnTests/Persistence/Accounts/SwiftDataAccountRepositoryTests.swift`

## Key Design Decisions

- Repository uses `@ModelActor`.
- Fetch-all ordering is deterministic by name and ID.
- Save updates an existing record by ID or inserts a new one.
- Delete is idempotent when a record is missing.

## Validation Requirements

- Tests cover fetch, fetch by ID, insert, update, delete, missing delete, and persistence round trips.
- Generic iOS Simulator build passes.

## Review Focus

- Actor isolation.
- Deterministic fetch ordering.
- Domain-only repository API.
- No unnecessary abstraction.

## Commit Intent

Commit the SwiftData Account repository and tests.
