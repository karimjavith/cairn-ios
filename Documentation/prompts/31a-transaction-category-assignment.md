# Milestone 31a: Transaction Category Assignment

Status: completed

## Objective

Unblock Milestone 31 by giving `Transaction` an optional `CategoryID` and giving `TransactionRepository` the smallest query capability needed to obtain category-scoped transactions.

## Scope

- Add optional `categoryID: CategoryID?` to the `Transaction` domain model.
- Preserve all existing transaction invariants.
- Update `Transaction` initialization and Codable behavior.
- Persist optional transaction category identity in `TransactionRecord`.
- Extend `TransactionRepository` with `fetchTransactions(categoryID:)`.
- Implement the category-scoped query in `SwiftDataTransactionRepository`.
- Update `CreateTransaction` to accept and preserve an optional category ID.
- Add focused tests for domain, persistence mapping, repository querying, and create workflow behavior.
- Update Milestone 31 documentation to reflect that this prerequisite resolves the category-assignment/query blocker.
- Update the prompt README.

## Constraints

- Do not implement Budget progress.
- Do not require transactions to have a category.
- Do not validate category existence.
- Do not add a `Category` object or reference to `Transaction`.
- Do not add a `CategoryRecord` relationship to `TransactionRecord`.
- Do not add a `CategoryRepository` dependency to transaction creation.
- Do not add generic predicates, query objects, pagination, arbitrary filtering APIs, or combined account/category/date repository overloads.
- Do not change existing account-scoped fetch, save, update, or delete semantics.
- Do not expose SwiftData from domain APIs.
- Do not add new SwiftData model types.

## Affected Files

- `App/Cairn/Core/Finance/Transaction.swift`
- `App/Cairn/Core/Finance/TransactionRepository.swift`
- `App/Cairn/Core/Finance/CreateTransaction.swift`
- `App/Cairn/Persistence/Transactions/TransactionRecord.swift`
- `App/Cairn/Persistence/Transactions/SwiftDataTransactionRepository.swift`
- `App/CairnTests/Core/Finance/TransactionTests.swift`
- `App/CairnTests/Core/Finance/CreateTransactionTests.swift`
- `App/CairnTests/Persistence/Transactions/TransactionRecordTests.swift`
- `App/CairnTests/Persistence/Transactions/SwiftDataTransactionRepositoryTests.swift`
- `Documentation/prompts/31a-transaction-category-assignment.md`
- `Documentation/prompts/31-budget-progress.md`
- `Documentation/prompts/README.md`

## Key Design Decisions

- Represent category assignment as `CategoryID?` on `Transaction`; `nil` means uncategorized.
- Keep category assignment as identifier-only data, with no `Category` object or persistence relationship.
- Do not validate category existence in the domain model or create workflow because that would require a new repository dependency and is outside this prerequisite.
- Keep the repository addition minimal with only `fetchTransactions(categoryID:)`.
- Use the same deterministic ordering as account-scoped transaction fetches: occurred date descending, then ID ascending.
- Continue reconstructing persisted transactions through validated `Transaction` initialization.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run `TransactionTests`.
- Run `TransactionRecordTests`.
- Run `SwiftDataTransactionRepositoryTests`.
- Run `CreateTransactionTests`.
- Run `/review` focused on the review areas below.
- Show `git status --short`.
- Show the complete relevant diff.

## Review Focus

- Minimality of the new repository capability.
- No generic query abstraction.
- Optional category semantics.
- ID fidelity.
- Codable and persistence compatibility.
- No `CategoryRecord` relationship.
- No unnecessary `CategoryRepository` dependency.
- No SwiftData leakage into domain.
- No regression to create/update repository semantics.

## Commit Intent

Commit optional transaction category assignment, category-scoped transaction repository fetching, focused tests, and milestone documentation updates.
