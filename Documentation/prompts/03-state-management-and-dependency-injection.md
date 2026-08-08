# 03 State Management and Dependency Injection

Status: completed

## Objective

Document state-management and dependency-injection rules that keep feature code explicit, testable, and free from hidden global dependencies.

## Scope

- Define when to use SwiftUI Observation.
- Prefer local state and immutable models where practical.
- Define constructor injection as the default dependency style.
- Limit SwiftUI environment usage to framework or truly application-wide concerns.

## Constraints

- Do not introduce service-locator architecture.
- Do not introduce application-wide singleton APIs.
- Do not create protocols only for architectural ceremony.

## Required Files or Areas

- `Documentation/ARCHITECTURE.md`
- `Documentation/ENGINEERING.md`
- `AGENTS.md`

## Key Design Decisions

- Feature dependencies should normally be passed explicitly.
- Protocols are used at meaningful dependency boundaries.
- Stateful services must have clear ownership and lifecycle.

## Validation Requirements

- Documentation must reinforce testability and explicit dependency ownership.
- Rules must remain compatible with SwiftUI-first development.

## Review Focus

- Avoidance of hidden global state.
- Practicality of dependency guidance.
- Consistency with future repository implementations.

## Commit Intent

Commit documentation for state ownership and dependency-injection conventions.
