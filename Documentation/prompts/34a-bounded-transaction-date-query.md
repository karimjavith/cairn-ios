# Milestone 34A: Bounded Transaction Date Query

Status: completed

## Objective

Unblock Milestone 34 by adding the smallest `TransactionRepository` capability required to retrieve all transactions in a finite period across accounts and categories.

## Scope

- Extend `TransactionRepository` with a bounded occurred-date query.
- Implement the query in `SwiftDataTransactionRepository`.
- Preserve the existing transaction record mapping boundary.
- Add focused SwiftData repository tests for the new query.
- Update existing `TransactionRepository` test doubles only where protocol conformance requires it.
- Do not implement the cash-flow calculator in this prerequisite milestone.

## Constraints

- Do not add unrestricted `fetchAll()`.
- Do not add generic predicates, query objects, pagination, arbitrary filtering, currency filtering, direction filtering, combined account/date APIs, or combined category/date APIs.
- Do not expose `ModelContext`, create another `ModelContainer`, introduce a global context, or introduce generic query infrastructure.
- Do not modify `Transaction` semantics.
- Keep currency and direction filtering as consumer responsibilities.

## Affected Files

- `App/Cairn/Core/Finance/TransactionRepository.swift`
- `App/Cairn/Persistence/Transactions/SwiftDataTransactionRepository.swift`
- `App/CairnTests/Persistence/Transactions/SwiftDataTransactionRepositoryTests.swift`
- Existing core finance tests with in-memory `TransactionRepository` test doubles
- `Documentation/prompts/34a-bounded-transaction-date-query.md`
- `Documentation/prompts/34-cash-flow-summary.md`
- `Documentation/prompts/README.md`

## Key Design Decisions

- Add only `fetchTransactions(occurredFrom:occurredBefore:)` because Milestone 34 needs account-independent, category-independent bounded transaction access.
- Use `start <= transaction.occurredAt && transaction.occurredAt < end`.
- Reject invalid or non-positive ranges explicitly with a small typed repository-contract error.
- Preserve established deterministic repository ordering: `occurredAt` descending, then stable transaction ID ordering.
- Continue mapping `TransactionRecord` to `Transaction` through the existing boundary so invalid persisted records fail rather than being skipped.
- Let SwiftData fetch errors propagate.

## Repository Contract

Add:

```swift
func fetchTransactions(
    occurredFrom start: Date,
    occurredBefore end: Date
) async throws -> [Transaction]
```

Semantics:

- account-independent
- category-independent
- start inclusive
- end exclusive

A transaction matches when:

```swift
start <= transaction.occurredAt && transaction.occurredAt < end
```

## Invalid Range

If `start >= end`, the query must fail explicitly with the smallest typed repository-contract error.

The repository must not:

- silently swap boundaries
- reinterpret the interval
- return an empty result for an invalid interval

## Ordering

Return deterministic ordering using the established transaction repository convention:

1. `occurredAt` descending
2. `TransactionID` stable tie-break

Consumers must not depend on ordering for calculation correctness, but repository output should remain stable.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `SwiftDataTransactionRepositoryTests` on a concrete available iPhone simulator
- Affected `Core/Finance` tests whose `TransactionRepository` test doubles require conformance updates
- `TransactionTests`

Focused repository tests must cover:

- transaction before start excluded
- transaction exactly at start included
- transaction inside interval included
- transaction exactly at end excluded
- transaction after end excluded
- matching transactions from multiple `AccountID` values are returned
- categorized transactions are returned
- uncategorized transactions are returned
- different `CategoryID` values are all returned when dates match
- multiple currencies are returned
- inflows are returned
- outflows are returned
- deterministic established ordering is preserved
- equal `occurredAt` values use the established stable ID tie-break
- invalid range behavior
- invalid persisted `TransactionRecord` mapping failure propagates rather than being skipped
- existing account-scoped fetch behavior remains unchanged
- existing category-scoped fetch behavior remains unchanged
- existing fetch/save/update/delete behavior remains unchanged

## Review Focus

- Minimal repository contract addition.
- Correct inclusive-start and exclusive-end date filtering.
- Account, category, currency, and direction independence.
- Invalid-range determinism.
- SwiftData predicate compatibility with iOS 17.
- Established ordering preservation.
- Mapping failure propagation.
- Existing repository behavior unchanged.
- No generic query or filtering abstraction creep.

## Commit Intent

Commit the bounded transaction date query prerequisite, its SwiftData implementation and tests, required test-double conformance updates, completed milestone documentation, and prompt README updates.
