# AGENTS.md

This file is the operating manual for AI coding agents working on Cairn.

## Project Overview

Cairn is a local-first personal financial operating system for iOS.

The project is:

- SwiftUI-first
- built with SwiftData persistence
- targeting iOS 17+
- privacy-first by default

## Engineering Principles

- Write production-quality code only.
- Do not add prototype code.
- Prefer pragmatism over over-engineering.
- Apply SOLID principles where they improve maintainability.
- Prefer composition over inheritance.
- Treat accessibility as a default requirement.
- Stay performance conscious.
- Stay security conscious.
- Keep technical debt low, intentional, and documented.

## Architecture Rules

Agents must read and follow:

- [Documentation/ARCHITECTURE.md](Documentation/ARCHITECTURE.md)
- [Documentation/ENGINEERING.md](Documentation/ENGINEERING.md)

Agents must not introduce architecture changes implicitly.

Any architectural change must be explicit and documented.

Agents must also:

- not introduce service-locator architecture
- not introduce application-wide singleton architecture
- not create protocols solely for architectural ceremony
- preserve the separation between domain models and persistence models
- avoid exposing SwiftData `@Model` objects as feature-domain APIs

## Coding Rules

- Use modern Swift.
- Use Swift Concurrency where appropriate.
- Keep types small and focused.
- Prefer value types.
- Avoid force unwraps except when they are provably safe.
- Avoid global state.
- Prefer dependency injection.
- Keep business logic out of SwiftUI views.
- SwiftUI views must not directly own business rules.
- Avoid coupling feature business logic directly to SwiftData `ModelContext`.
- Prefer explicit dependencies over hidden/global dependencies.

## Repository Rules

- Do not move files without reason.
- Do not invent new top-level folders.
- Keep features organized feature-first.
- Put shared code in `Core` only when it is genuinely shared.

## Workflow Rules

For every task:

- inspect the relevant existing code and documentation first
- keep the change scoped to the requested task
- run the build when production code or project configuration changes
- run relevant tests when behavior changes
- run `git -c core.fsmonitor=false diff --check`
- show git status
- show the complete relevant git diff
- never commit unless explicitly instructed
- do not silently weaken tests, accessibility, security, privacy, or error handling to make a task pass
