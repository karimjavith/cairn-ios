# 20 Category Repository

Status: completed

## Objective

Implement the SwiftData-backed `CategoryRepository` using the existing `CategoryRecord` mapping boundary.

## Scope

- Add an actor-backed SwiftData repository.
- Implement fetch all, fetch by ID, save, and delete.
- Preserve mapping through `CategoryRecord`.

## Constraints

- Do not expose SwiftData records or contexts.
- Do not add generic repository abstractions.
- Keep behavior deterministic and domain-facing.

## Required Files or Areas

- `App/Cairn/Persistence/Categories/SwiftDataCategoryRepository.swift`
- `App/CairnTests/Persistence/Categories/SwiftDataCategoryRepositoryTests.swift`

## Key Design Decisions

- Repository uses `@ModelActor`.
- Fetch-all ordering is deterministic by name and ID.
- Save updates existing records by ID or inserts new records.
- Delete is idempotent when the category does not exist.

## Validation Requirements

- Tests cover fetch, ordering, fetch by ID, insert, update, delete, and missing delete.
- Generic iOS Simulator build passes.

## Review Focus

- Deterministic ordering.
- Actor-backed SwiftData compatibility.
- Domain-only repository API.

## Commit Intent

Commit the SwiftData Category repository and tests.
