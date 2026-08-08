# 02 Architecture Structure and Boundaries

Status: completed

## Objective

Define Cairn's architecture principles, source layout, dependency direction, and boundaries between presentation, domain, persistence, and app composition.

## Scope

- Document local-first, SwiftUI-first, feature-first, and domain-driven architecture.
- Define responsibilities for `App`, `Features`, `Core`, `Persistence`, and `Resources`.
- Preserve domain independence from SwiftUI and SwiftData.

## Constraints

- Do not introduce architecture changes implicitly.
- Do not create speculative top-level folders.
- Avoid service locators, global singleton architecture, and protocols without purpose.

## Required Files or Areas

- `Documentation/ARCHITECTURE.md`
- `Documentation/ENGINEERING.md`
- `AGENTS.md`

## Key Design Decisions

- Domain models remain independent of SwiftData.
- SwiftData records live in `Persistence` and are not feature-domain APIs.
- Shared code belongs in `Core` only when genuinely shared.

## Validation Requirements

- Architecture documentation must align with engineering standards.
- Repository structure described in docs must match the current project direction.

## Review Focus

- Dependency direction and layer boundaries.
- Separation between domain and persistence.
- Simplicity and resistance to premature abstraction.

## Commit Intent

Commit architecture documentation that defines structure and dependency boundaries.
