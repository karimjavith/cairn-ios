# Milestone 29: Create Transaction Workflow

Status: completed

## Objective

Create the first focused Cairn application/business workflow for creating a `Transaction`.

## Scope

- Add a use case that receives explicit `AccountRepository` and `TransactionRepository` dependencies.
- Accept the information needed to construct a transaction: `TransactionID`, `AccountID`, `TransactionDirection`, `Money`, occurrence date, and optional memo.
- Validate cross-aggregate rules before persistence.
- Reject an existing `TransactionID` before saving so create semantics do not rely on repository upsert behavior.
- Save the validated transaction through `TransactionRepository`.
- Return the created `Transaction` after successful persistence.
- Add focused workflow tests with in-memory test doubles.

## Constraints

- Do not create a generic service layer.
- Do not introduce service locators, singleton repository access, SwiftUI `Environment` dependencies, or custom concurrency infrastructure.
- Do not import SwiftData or depend on persistence records.
- Do not modify repository contracts or persistence implementations unless a genuine blocker is discovered.
- Do not mutate `Account.openingBalance`, add `currentBalance`, persist running balances, or calculate derived account balances.
- Do not add transfers, category assignment, recurring transaction generation, budget updates, goal updates, notifications, analytics, undo, or batch operations.
- Reuse the existing `Transaction` initializer for domain invariants instead of duplicating transaction validation.

## Affected Files

- `App/Cairn/Core/Finance/CreateTransaction.swift`
- `App/CairnTests/Core/Finance/CreateTransactionTests.swift`
- `Documentation/prompts/29-create-transaction-workflow.md`
- `Documentation/prompts/README.md`

## Key Design Decisions

- Place the use case in `Core/Finance` because the current architecture keeps shared finance domain types and repository contracts there, and no feature-specific transaction workflow location exists yet.
- Use constructor injection for repositories.
- Use a small typed use-case error for application-specific failures: `accountNotFound` and `currencyMismatch`.
- Use a small typed duplicate-ID error so the create workflow cannot silently overwrite an existing transaction through repository upsert semantics.
- Let repository and domain errors propagate naturally.
- Compare the transaction `Money.currencyCode` with `Account.currencyCode`, relying on existing `Money` and `Account` normalization semantics.
- Check duplicate transaction identity after account and currency validation but before domain construction and save; this keeps cross-aggregate validation deterministic while preserving create-only semantics.
- Keep the workflow independent of `MainActor`.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run focused `CreateTransaction` workflow tests on a concrete simulator.
- Run existing `Transaction` domain tests.
- Run existing `Account` domain tests.
- Run `/review` focused on the review areas below.
- Show `git status --short`.
- Show the complete relevant diff.

## Review Focus

- Correct application-layer responsibility.
- Cross-aggregate validation.
- Currency consistency.
- Account-not-found semantics.
- Domain invariant reuse rather than duplication.
- Explicit dependency injection.
- `Sendable` and concurrency correctness.
- Repository error propagation.
- Absence of SwiftData or UI leakage.
- Unnecessary abstraction.
- Whether this establishes a good reference pattern for future application workflows.

## Commit Intent

Commit the focused create-transaction workflow, its tests, and the milestone documentation update.
