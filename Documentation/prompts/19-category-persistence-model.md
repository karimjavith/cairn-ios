# 19 Category Persistence Model

Status: completed

## Objective

Create the SwiftData persistence model and mapping boundary for `Category`.

## Scope

- Add `CategoryRecord` as a SwiftData `@Model`.
- Persist category ID, name, and kind.
- Add explicit mapping between `Category` and `CategoryRecord`.
- Register the record in the centralized schema.

## Constraints

- Do not implement the repository in this milestone.
- Do not add relationships, colors, icons, hierarchy, or metadata.
- Preserve `CategoryID` across round trips.
- Keep domain independent of SwiftData.

## Required Files or Areas

- `App/Cairn/Persistence/Categories/CategoryRecord.swift`
- `App/CairnTests/Persistence/Categories/CategoryRecordTests.swift`
- `App/Cairn/App/CairnApp.swift`

## Key Design Decisions

- ID persists as `UUID`.
- Kind persists as a stable string.
- Mapping back reconstructs through `Category` validation.

## Validation Requirements

- Tests cover value preservation, ID preservation, kind mapping, name normalization, invalid kind, invalid name, and in-memory SwiftData round trip.
- Generic iOS Simulator build passes.

## Review Focus

- CategoryID preservation.
- Kind mapping error design.
- Persistence/domain separation.

## Commit Intent

Commit Category SwiftData record, mapping tests, and schema registration.
