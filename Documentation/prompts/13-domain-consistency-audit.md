# 13 Domain Consistency Audit

Status: completed

## Objective

Audit existing finance domain models for consistent validation, normalization, Codable reconstruction, Sendable conformance, and test coverage.

## Scope

- Review Money, Account, Transaction, Category, Budget, Goal, and RecurringTransaction.
- Align naming and validation behavior where needed.
- Ensure decoding applies domain invariants.

## Constraints

- Do not change domain semantics without a clear correctness reason.
- Do not introduce persistence or UI dependencies.
- Keep fixes narrow and well-tested.

## Required Files or Areas

- `App/Cairn/Core/Finance/`
- `App/CairnTests/Core/Finance/`

## Key Design Decisions

- Domain decoding should call validated initializers.
- Normalization should be deterministic and tested.
- Domain models remain value types and Sendable where appropriate.

## Validation Requirements

- Run affected finance domain tests.
- Build the app target when production files change.
- Check diff cleanliness.

## Review Focus

- Consistency across domain models.
- Preservation of existing intended semantics.
- Test coverage for invariant enforcement.

## Commit Intent

Commit narrow domain consistency fixes and tests.
