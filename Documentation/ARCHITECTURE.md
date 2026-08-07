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
