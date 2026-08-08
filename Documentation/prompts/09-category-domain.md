# 09 Category Domain

Status: completed

## Objective

Create the `Category` domain model for classifying income and expense activity.

## Scope

- Add `CategoryID`, `CategoryKind`, and `Category`.
- Support income and expense category kinds.
- Validate category names.

## Constraints

- Do not implement persistence.
- Do not add hierarchy, budgeting behavior, colors, icons, or metadata.
- Keep the model independent of SwiftUI and SwiftData.

## Required Files or Areas

- `App/Cairn/Core/Finance/Category.swift`
- `App/CairnTests/Core/Finance/CategoryTests.swift`

## Key Design Decisions

- Category names are trimmed and empty names are rejected.
- Category kind is a small domain enum.
- IDs wrap `UUID`.

## Validation Requirements

- Tests cover construction, validation, Codable behavior, equality/hashability, and Sendable.

## Review Focus

- Minimal domain surface.
- No presentation or persistence concerns.
- Clear validation errors.

## Commit Intent

Commit the category domain model and tests.
