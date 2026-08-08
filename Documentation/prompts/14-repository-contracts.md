# 14 Repository Contracts

Status: completed

## Objective

Add domain-level repository protocols that define persistence capabilities without coupling domain consumers to SwiftData.

## Scope

- Add repository contracts for accounts, transactions, categories, budgets, goals, and recurring transactions.
- Use async throwing APIs.
- Keep contracts in domain terms.

## Constraints

- Do not implement repositories in this milestone.
- Do not expose SwiftData `ModelContext` or `@Model` types.
- Do not create generic repository abstractions.

## Required Files or Areas

- `App/Cairn/Core/Finance/AccountRepository.swift`
- `App/Cairn/Core/Finance/TransactionRepository.swift`
- `App/Cairn/Core/Finance/CategoryRepository.swift`
- `App/Cairn/Core/Finance/BudgetRepository.swift`
- `App/Cairn/Core/Finance/GoalRepository.swift`
- `App/Cairn/Core/Finance/RecurringTransactionRepository.swift`

## Key Design Decisions

- Protocols are `Sendable`.
- CRUD-like operations are expressed in domain types and IDs.
- Transaction fetching is account-scoped.

## Validation Requirements

- Build the app target.
- Verify domain remains independent of persistence.

## Review Focus

- Contract shape and future actor-backed suitability.
- No generic abstraction or service locator.
- No SwiftData leakage into domain.

## Commit Intent

Commit finance repository protocol contracts.
