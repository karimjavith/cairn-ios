# Milestone 22: Strict Decimal Persistence Consistency

Status: completed

## Objective

Audit and fix persisted `Decimal` parsing consistency across the existing finance persistence models so malformed monetary strings are rejected instead of being partially parsed.

## Scope

Inspect and update only the existing finance persistence records that map persisted monetary strings back into domain models:

- `App/Cairn/Persistence/Accounts/AccountRecord.swift`
- `App/Cairn/Persistence/Transactions/TransactionRecord.swift`
- `App/Cairn/Persistence/Budgets/BudgetRecord.swift`

`BudgetRecord` is the reference behavior for strict persisted decimal parsing unless a better minimal implementation is clearly justified.

## Constraints

- Persisted monetary strings must represent the entire `Decimal` value.
- Reject malformed values such as `12abc`, `1,23`, and non-numeric text.
- Parsing must be locale-independent.
- Parsing must preserve `Decimal` precision.
- Parsing must never convert through `Double` or `Float`.
- Valid negative numeric text must continue to parse so domain validation remains responsible for rejecting invalid negative monetary state where applicable.
- Malformed data must never be silently repaired, truncated, or defaulted.
- Error behavior must remain typed and explicit, using each record's existing mapping error design.
- Do not introduce generic decimal parser services, generic persistence frameworks, DTOs, global helpers, or unnecessary abstractions.
- Prefer small private/local duplication over premature shared abstraction.
- Do not change domain models, repository protocols, SwiftData schemas, repository implementations, or Budget behavior unless a regression is discovered.

## Affected Files

- `Documentation/prompts/22-strict-decimal-persistence-consistency.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Persistence/Accounts/AccountRecord.swift`
- `App/Cairn/Persistence/Transactions/TransactionRecord.swift`
- `App/CairnTests/Persistence/Accounts/AccountRecordTests.swift`
- `App/CairnTests/Persistence/Transactions/TransactionRecordTests.swift`

## Key Design Decisions

- Keep decimal validation private to each affected record, matching the existing `BudgetRecord` local parsing style.
- Use a full-string numeric regular expression before calling `Decimal(string:)` so Foundation cannot partially accept malformed persisted values.
- Continue serializing `Decimal` through `NSDecimalNumber(decimal:).stringValue` to preserve existing persistence output.
- Keep negative numeric strings syntactically valid at the persistence mapping layer; domain validation remains responsible for rejecting invalid negative account, transaction, or budget state.
- Avoid shared parser abstractions until more persistence models prove the duplication is a maintenance burden.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `AccountRecordTests`
- `TransactionRecordTests`
- `BudgetRecordTests`
- Relevant Account and Transaction domain regression tests
- `/review`

## Review Focus

- Strict full-string `Decimal` parsing
- Locale independence
- Precision preservation
- No silent coercion, truncation, repair, or defaulting
- Consistent typed mapping error semantics
- No unnecessary abstraction
- No domain/persistence leakage

## Commit Intent

One scoped commit updating Account and Transaction persistence decimal parsing to match Budget's strict behavior, with focused regression coverage and milestone documentation.
