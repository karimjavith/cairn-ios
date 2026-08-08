# 04 Application Composition

Status: completed

## Objective

Define the application composition root, SwiftData container ownership, root navigation responsibilities, and future infrastructure assembly points.

## Scope

- Document that the app layer owns application startup and composition.
- Define centralized SwiftData `ModelContainer` creation.
- Keep feature code from constructing concrete infrastructure dependencies directly.

## Constraints

- Do not create multiple app-level composition roots.
- Do not move product business rules into `App`.
- Avoid global navigation objects that know every feature internals.

## Required Files or Areas

- `Documentation/ARCHITECTURE.md`
- `App/Cairn/App/`
- Future persistence container registration

## Key Design Decisions

- `ModelContainer` is created at application startup.
- Persistence configuration belongs in the persistence/app composition boundary.
- Future infrastructure plugs into the composition root instead of features creating it ad hoc.

## Validation Requirements

- Documentation must align with the existing app entry point direction.
- No feature behavior should be introduced by this milestone.

## Review Focus

- Clear app-layer responsibilities.
- No business logic in the composition root.
- Future suitability for repositories and SwiftData.

## Commit Intent

Commit composition-root and application assembly guidance.
