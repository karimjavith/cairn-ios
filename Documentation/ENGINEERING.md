Cairn Engineering Standards

Purpose

Cairn is a commercial-quality, local-first personal financial operating system for iOS.

Every engineering decision should optimize for:

- correctness
- maintainability
- privacy
- accessibility
- testability
- long-term product velocity

We build production software, not prototypes.

⸻

Platform

Minimum platform:

- iOS 17+

Technology stack:

- Swift
- SwiftUI
- SwiftData
- Swift Concurrency
- Xcode (current stable)

Apple frameworks are preferred over third-party dependencies whenever practical.

⸻

Engineering Principles

- Production-ready code only.
- Prefer simplicity over cleverness.
- Prefer pragmatism over unnecessary abstraction.
- Composition over inheritance.
- Value types by default.
- SOLID principles where they improve maintainability.
- Keep technical debt intentional and documented.
- Optimize for readability.

⸻

Repository Structure

The repository is organized by responsibility.

App/
Documentation/
Scripts/

The Xcode project lives under App/.

Documentation belongs in Documentation/.

Automation and tooling belong in Scripts/.

⸻

Architecture

Cairn follows a feature-first architecture.

Features own their UI, domain logic and feature-specific services.

Shared infrastructure should exist only when genuinely shared.

Maintain clear boundaries between:

- Presentation
- Domain
- Persistence
- Infrastructure

Business logic must never live inside SwiftUI view bodies.

⸻

SwiftUI

SwiftUI is the primary UI framework.

Views should:

- remain small
- compose other views
- contain presentation logic
- avoid business rules

Prefer native SwiftUI controls over custom implementations.

Follow Apple’s Human Interface Guidelines.

⸻

State Management

Choose the simplest ownership model that solves the problem.

Prefer:

- immutable models
- local state where possible
- explicit observable state where necessary

Avoid unnecessary global state.

Avoid introducing architectural layers simply to mirror popular patterns.

⸻

Persistence

SwiftData is the default persistence layer.

Requirements:

- deterministic persistence
- schema migrations
- recoverable failures
- data integrity

Financial data must never be silently discarded.

⸻

Concurrency

Use structured concurrency.

Prefer:

- async/await
- actors
- task groups when appropriate

Avoid detached tasks unless explicitly justified.

UI updates belong on the MainActor.

⸻

Error Handling

Errors should never disappear silently.

Recover locally when possible.

Otherwise:

- propagate
- log appropriately
- present meaningful user feedback

User-facing messages should explain:

- what happened
- what the user can do next

⸻

Testing

Design production code to be testable.

Prioritize tests for:

- financial calculations
- persistence
- migrations
- state transitions
- regressions

UI tests should focus on critical user journeys.

⸻

Accessibility

Accessibility is part of implementation.

Support:

- Dynamic Type
- VoiceOver
- sufficient touch targets
- semantic labels
- reduced motion
- dark mode
- light mode

Accessibility regressions are bugs.

⸻

Security & Privacy

Financial information is sensitive.

Principles:

- local-first
- collect the minimum data required
- never commit secrets
- never log sensitive financial information
- prefer Apple security APIs
- review every future cloud dependency

Privacy is a product feature.

⸻

Performance

Avoid premature optimization.

However, always be aware of:

- unnecessary SwiftUI invalidation
- excessive allocations
- expensive work on the main thread
- inefficient SwiftData fetches
- large collection rendering

Measure before optimizing.

⸻

Dependencies

Every dependency has a maintenance cost.

Before adding one, ask:

1. Can Apple frameworks solve this?
2. Is it actively maintained?
3. Does it improve the product enough?
4. Is the security risk acceptable?
5. Can we remove it later?

Small convenience libraries are rarely justified.

⸻

Code Review

Every pull request should improve the codebase.

Review for:

- correctness
- readability
- architecture
- testing
- accessibility
- security
- performance

Do not approve code simply because it works.

⸻

Definition of Done

A change is complete only when:

- builds cleanly
- introduces no new warnings
- appropriate tests pass
- accessibility has been considered
- error paths have been considered
- documentation is updated where required
- unnecessary complexity has been avoided

⸻

Technical Debt

Technical debt must be intentional.

If a shortcut is taken:

- document why
- record how it should be resolved
- create a follow-up task if appropriate

The default approach is to solve the problem correctly the first time.
