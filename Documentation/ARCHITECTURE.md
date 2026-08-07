# Cairn Architecture

## Purpose

This document defines the architectural principles, boundaries, and conventions for Cairn.

Its purpose is to ensure the application evolves as a coherent system over many years while remaining maintainable, testable, performant, and privacy-first.

Implementation should follow this document unless there is a deliberate architectural decision to change it.

---

# Architectural Principles

Cairn follows several core principles.

## Local First

User data belongs to the user.

The application should function without a network connection whenever possible.

Cloud synchronization is an enhancement, not a dependency.

---

## Feature First

The codebase is organized around product capabilities rather than technical layers.

Each feature owns its:

- UI
- domain logic
- feature services
- tests

Shared code exists only when genuinely shared.

---

## SwiftUI First

SwiftUI is the primary UI framework.

UIKit should only be introduced when SwiftUI cannot reasonably provide the required functionality.

---

## Domain Driven

Business rules are independent from presentation.

Financial calculations should remain testable without SwiftUI or SwiftData.

---

## Separation of Responsibilities

Every layer has one responsibility.

Presentation should not know persistence details.

Persistence should not contain business rules.

Infrastructure should not drive application behavior.

---

## Privacy by Design

Financial information is treated as sensitive.

Local storage is the default.

Every future external dependency should justify the privacy implications it introduces.

---

## Simplicity

Prefer straightforward solutions.

Avoid architectural patterns that exist only to satisfy trends or frameworks.

Complexity should be introduced only when it solves a demonstrated problem.

---

# Structure

The repository and application source should remain organized around clear ownership boundaries.

## Repository Structure

The repository-level structure is:

```text
cairn-ios/
├── App/
│   ├── Cairn.xcodeproj
│   ├── Cairn/
│   ├── CairnTests/
│   └── CairnUITests/
├── Documentation/
├── Scripts/
└── .github/
```

Responsibilities:

- `App/` contains the Xcode project, application source, and test targets.
- `Documentation/` contains product, engineering, and architecture documentation.
- `Scripts/` contains automation and local development tooling.
- `.github/` contains GitHub-specific automation, workflows, and repository configuration.

## Application Source Structure

Application source under `App/Cairn/` should use this structure:

```text
App/
Features/
Core/
Persistence/
Resources/
```

### App

`App` owns application composition.

It is responsible for:

- application entry point
- root navigation
- dependency composition
- lifecycle and environment configuration

`App` must not contain product business rules.

### Features

`Features` is organized by product capability.

Example features may include:

- Dashboard
- Accounts
- Transactions
- Budgets
- Settings

Each feature should own the UI, domain logic, feature services, and tests needed for that capability.

Where useful, a feature may use this internal structure:

```text
FeatureName/
├── Presentation/
├── Domain/
└── Support/
```

Not every feature needs every directory.

Empty structural folders should not be created speculatively.

#### Presentation

`Presentation` contains SwiftUI-facing feature code.

It is responsible for:

- SwiftUI screens
- feature-specific reusable views
- presentation state
- navigation destinations

Presentation may depend on domain abstractions.

Presentation must not directly depend on concrete persistence implementation details.

#### Domain

`Domain` contains feature business behavior.

It is responsible for:

- business rules
- value types
- calculations
- policies
- validation
- use cases
- domain services

Domain must not depend on SwiftUI.

Domain should remain independent of SwiftData where practical.

#### Support

`Support` contains feature-specific helpers that do not belong in presentation or domain.

Use `Support` sparingly.

It must not become a dumping ground.

### Core

`Core` contains genuinely shared capabilities used across multiple features.

Examples include:

- foundational value types
- shared protocols
- logging abstractions
- currency utilities
- date utilities
- application-wide design primitives

Do not move code into `Core` merely because it is reused once.

Prefer trivial duplication over premature shared abstractions.

Shared code belongs in `Core` only when multiple features depend on it for the same reason and the abstraction is stable enough to justify the shared ownership.

### Persistence

`Persistence` owns SwiftData-specific infrastructure.

It is responsible for:

- SwiftData models
- `ModelContainer` configuration
- repositories
- schema versions
- migration plans
- persistence mapping

Business logic should not couple directly to `ModelContext`.

### Resources

`Resources` contains application-wide assets, localization, and configuration resources.

Feature-specific resources should remain with their feature where practical.

---

# Dependency Direction

Dependencies should flow through the system in this direction:

```text
SwiftUI Presentation
        ↓
      Domain
        ↑
Persistence / Infrastructure
```

Rules:

- Domain must not depend on presentation.
- Domain should not depend on concrete persistence implementations.
- Persistence and infrastructure adapt external systems to domain concepts.
- Cross-feature dependencies should be rare and explicit.
- Do not introduce separate Swift packages yet.
- Modularize later only when real boundaries justify the build complexity.

---

# State Management and Dependency Injection

## State Management

- Use SwiftUI Observation (`@Observable`) for feature state where appropriate.
- State should be owned by the feature that requires it.
- Avoid global mutable state.
- Keep presentation state separate from business rules.
- Keep state as small and focused as practical.

## Dependency Injection

- Prefer constructor injection.
- Introduce protocols at meaningful dependency boundaries where substitution, isolation, or testing benefits justify the abstraction.
- Do not create protocols solely for architectural ceremony.
- Environment values are reserved for truly application-wide dependencies or SwiftUI-propagated concerns.
- Feature-specific dependencies should normally be passed explicitly.
- Avoid service locators.
- Avoid singleton-based application architecture.

## Services

Services should prefer stateless behavior when state is unnecessary.

When a service must own state:

- ownership must be explicit
- lifecycle must be clear
- concurrency/isolation requirements must be defined
- shared mutable state should be avoided unless genuinely required

Examples include:

- Date providers
- Currency formatting
- Logging
- Import/export
- Synchronization

Services must not become repositories of unrelated functionality.

## Testing

- Business logic should be testable without SwiftUI.
- Business logic should be testable without SwiftData where practical.
- Dependencies should be replaceable with test doubles.
