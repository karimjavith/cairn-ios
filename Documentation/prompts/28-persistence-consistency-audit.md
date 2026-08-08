# Milestone 28: Persistence Consistency Audit

Status: completed

## Objective

Audit the completed persistence phase for consistency, correctness, data integrity, domain isolation, and SwiftData readiness before treating the persistence layer as a stable foundation for application workflows.

## Audit Scope

- Persistence models and mapping boundaries for `Account`, `Transaction`, `Category`, `Budget`, `Goal`, and `RecurringTransaction`.
- Concrete SwiftData repositories for the same aggregates.
- Domain repository protocols in `App/Cairn/Core/Finance`.
- Centralized schema registration in the application composition root.
- Persistence test coverage in `App/CairnTests/Persistence`.

## Constraints

- Audit before production code changes.
- Fix only findings that represent correctness risk, data-integrity risk, architecture-boundary violation, concurrency/isolation problem, or meaningful missing regression coverage.
- Do not modify code merely because implementations differ stylistically.
- Do not alter domain semantics or add product behavior.
- Do not introduce generic repository base classes, mapper protocols, CRUD frameworks, service locators, persistence singletons, DTO layers, or generic sorting frameworks.
- Keep any fixes and tests tightly scoped.

## Validation Requirements

- Run `git -c core.fsmonitor=false diff --check`.
- Run a generic iOS Simulator build.
- Run the full `CairnTests` unit-test target on a concrete available iPhone simulator if practical.
- If full tests cannot run, run every persistence test suite plus all affected domain suites.
- Verify centralized schema registration.
- Verify no production source outside justified audit fixes changed.
- Run `/review`.

## Review Focus

- Data-integrity bugs missed by individual milestones.
- Decimal locale independence across all monetary persistence.
- SwiftData actor isolation and iOS 17 compatibility.
- Domain/persistence boundaries and schema/container ownership.
- CRUD consistency, deterministic ordering, ID fidelity, and invalid-state propagation.
- Optional-value fidelity and enum persistence behavior.
- Over-abstraction risk.
- Whether the persistence layer is ready to support application workflows.

## Audit Findings

### Correctness Issues

- `AccountRecord`, `TransactionRecord`, `BudgetRecord`, and `GoalRecord` validated dot-decimal persisted monetary strings but reconstructed with locale-sensitive `Decimal(string:)`. This was a data-integrity risk because the persisted representation uses dot-decimal text while parsing could depend on the user's current locale.

### Architectural Inconsistencies

- None found. Domain models and repository protocols remain SwiftData-independent and do not expose `@Model`, `ModelContext`, or `ModelContainer`.
- Concrete repositories consistently use `@ModelActor`, keep `ModelContext` private, return domain values, and propagate SwiftData and mapping errors.
- Production schema/container ownership remains centralized in `CairnApp`.

### Test Gaps

- Record tests covered malformed comma decimal text but did not explicitly cover valid persisted dot-decimal reconstruction against a fixed persistence locale for `AccountRecord`, `TransactionRecord`, `BudgetRecord`, and `GoalRecord`.

### Harmless Implementation Differences

- `Account`, `Transaction`, `Category`, and `Budget` repositories use SwiftData sort descriptors where persisted fields are straightforward to sort.
- `Goal` and `RecurringTransaction` repositories fetch records and sort mapped domain values in memory to avoid optional-date SwiftData sorting concerns on iOS 17.
- Decimal parsing helpers remain duplicated locally in each record by design; the duplication is small and avoids premature shared infrastructure.

## Fixes Made

- Updated `AccountRecord`, `TransactionRecord`, `BudgetRecord`, and `GoalRecord` to parse persisted monetary text with `Locale(identifier: "en_US_POSIX")` after strict full-string validation.
- Added focused record-level regression tests for valid dot-decimal and exponent persisted monetary text for the affected records.
- Left `RecurringTransactionRecord` unchanged because it already used the fixed-locale approach.

## Commit Intent

One scoped commit documenting the persistence consistency audit and applying only justified fixes with focused regression coverage. Do not stage or commit during implementation.
