# 06 Money Domain

Status: completed

## Objective

Create the core `Money` value type for exact financial amounts and validated currency codes.

## Scope

- Add a domain value type using `Decimal` for amounts.
- Validate ISO currency codes.
- Normalize currency text.
- Support same-currency addition and subtraction.

## Constraints

- Do not use `Double` or `Float` for monetary values.
- Do not depend on SwiftUI or SwiftData.
- Keep the type small, value-based, and Sendable.

## Required Files or Areas

- `App/Cairn/Core/Finance/Money.swift`
- `App/CairnTests/Core/Finance/MoneyTests.swift`

## Key Design Decisions

- `Money` stores `Decimal` and uppercase ISO currency code.
- Invalid amount and invalid currency failures are typed as `MoneyError`.
- Arithmetic requires matching currencies and returns validated `Money`.

## Validation Requirements

- Tests cover currency normalization, invalid currencies, invalid amounts, arithmetic, and currency mismatch.
- Domain tests run without SwiftUI or SwiftData.

## Review Focus

- Decimal precision.
- Currency validation and normalization.
- Absence of persistence or UI leakage.

## Commit Intent

Commit the foundational monetary domain value type and tests.
