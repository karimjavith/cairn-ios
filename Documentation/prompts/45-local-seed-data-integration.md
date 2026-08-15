# Milestone 45: Local Seed-Data Integration

Status: completed

## Objective

Add a development-only mechanism for loading local seed data into Cairn.

The seed integration is for developer convenience only. It must never require or expose a production UI path, never seed release builds, and never commit a real seed payload.

## Critical Git Safety Rule

The actual seed-data file remains local to the developer machine.

Do not commit:

- `Local/SeedData/`
- `Local/SeedData/cairn-seed.json`
- placeholder seed payloads
- sample personal finance data

The repository may contain only:

- source code for the seed-loading mechanism
- tests that build fixtures in memory or temporary files
- `.gitignore` rules for the local seed path
- documentation of the expected local path and JSON shape

## Chosen Local Path

Use this deterministic repository-relative local-only path:

```text
Local/SeedData/cairn-seed.json
```

Add `Local/SeedData/` to `.gitignore`.

If a developer wants local seed data, they create the directory and file manually on their machine.

## JSON Format

Use a narrow, versioned JSON document:

```json
{
  "schemaVersion": 1,
  "accounts": [],
  "categories": [],
  "transactions": [],
  "budgets": [],
  "goals": [],
  "recurringTransactions": []
}
```

The format supports existing domain aggregates only:

- `Account`
- `Category`
- `Transaction`
- `Budget`
- `Goal`
- `RecurringTransaction`

Do not invent unsupported fields.

DTOs should remain local to the seed integration boundary and map into domain values. Seed decoding must preserve IDs supplied by the payload.

Use ISO-8601 date strings.

## Loading Behavior

Seed loading must be DEBUG-only.

Use explicit opt-in:

- launch argument: `--cairn-load-local-seed-data`
- environment variable: `CAIRN_LOAD_LOCAL_SEED_DATA=1`

If neither opt-in is present, the app launches normally and does not look for the seed file.

If opt-in is present in DEBUG:

- read `Local/SeedData/cairn-seed.json`
- fail explicitly if the file is missing
- decode and validate the seed payload
- seed only if the current store is empty
- refuse/no-op if any existing persisted entity is present
- preserve all payload IDs

Release/non-DEBUG builds must not seed, even if the launch argument or environment variable is present.

## Idempotence and Safety

Use an empty-store policy.

Before importing, check that all supported repositories are empty:

- accounts
- categories
- transactions using the existing bounded date query
- budgets
- goals
- recurring transactions

If the store is not empty, return a typed `storeNotEmpty` result/error and do not save any seed data.

Repeated seed attempts against a successfully seeded store must not duplicate data because the second attempt observes a non-empty store and refuses to import.

Do not merge blindly with user data.

Do not wipe data.

Do not generate replacement IDs.

## Validation

Seed decoding must reconstruct domain values through existing validated domain initializers.

Do not bypass:

- `Money` validation
- enum validation
- `BudgetPeriod` validation
- `Goal` invariants
- `RecurringTransaction` invariants
- memo/name normalization

Malformed JSON, unsupported versions, invalid dates, invalid money, invalid enum values, and invalid domain data must fail explicitly.

Do not silently repair invalid values.

## Referential Dependency Order

Save seeded domain values in a coherent order:

1. accounts
2. categories
3. transactions
4. budgets
5. goals
6. recurring transactions

This order ensures account/category dependencies exist before transactions, categories exist before budgets, and accounts exist before recurring transactions.

The current domain and repository contracts do not enforce all foreign-key references, so this milestone should not invent a broad referential integrity framework. The seed loader should still preserve provided IDs and import in dependency-safe order.

## Persistence Boundary

Use existing repositories.

Do not:

- expose SwiftData models in the JSON format
- expose `ModelContext`
- create a second production `ModelContainer`
- write seed logic in SwiftUI views
- create a generic import/export framework

The app composition layer may construct and run the DEBUG seed loader after creating the normal production repositories.

## Error Behavior

Use focused seed-loading errors where useful:

- opt-in disabled
- release build unavailable
- missing file
- unsupported version
- decode failure
- invalid domain data
- store not empty

Do not stringify arbitrary errors in core seed logic. App composition may print a concise DEBUG diagnostic because this is local-development infrastructure.

## Test Strategy

Tests must not read the developer's actual local seed file.

Use in-memory JSON data or temporary test files.

Cover at minimum:

- valid versioned seed decodes
- unsupported version fails
- malformed JSON fails
- invalid monetary/domain data fails
- IDs are preserved
- account/category/transaction relationships by ID are preserved
- empty store can seed
- non-empty store refuses/no-ops
- repeated seed attempt does not duplicate data
- missing local file behavior
- seed opt-in disabled does not load
- release/non-DEBUG path does not seed where testable

## Documentation Requirements

After implementation, update this document with:

- final architecture
- chosen local path
- JSON shape/version
- opt-in mechanism
- empty-store policy
- developer setup instructions
- explicit statement that seed payload stays local and must never be committed
- validation performed

Set status to `completed`.

Update `Documentation/prompts/README.md`.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused seed-data integration tests
4. `git check-ignore -v Local/SeedData/cairn-seed.json`
5. `git -c core.fsmonitor=false ls-files Local/SeedData/cairn-seed.json Local/SeedData`

The final `ls-files` check must return no tracked seed payload.

Do not run the full `CairnTests` suite unless necessary.

Do not run `/review`.

Do not stage or commit.

## Review Focus

- No seed payload file is created or committed.
- `.gitignore` protects the chosen local path.
- Seed loading is DEBUG-only and explicit opt-in.
- Missing file only matters when opt-in is requested.
- Store-not-empty refuses/no-ops without writes.
- Domain validation is used for decoded values.
- IDs are preserved.
- Repositories are used for persistence.
- No SwiftData details leak into seed JSON or feature UI.

## Final Architecture

The local seed integration is app-owned and lives at:

```text
App/Cairn/App/LocalSeedDataLoader.swift
App/Cairn/App/LocalSeedDataBootstrapCoordinator.swift
```

`CairnApp` still owns the single production `ModelContainer`. It now stores the concrete SwiftData repositories in local variables, passes them into `AppDependencies`, and, in DEBUG builds only, constructs `LocalSeedDataLoader` with those same repository instances.

No feature view or feature store knows about seed data.

DEBUG startup is coordinated by `LocalSeedDataBootstrapCoordinator` at the app composition boundary.

When seed opt-in is not active, the coordinator reports `notRequired` immediately and the normal `RootView` is available without an extra repository operation.

When seed opt-in is active, the coordinator starts in `loading`, `CairnApp` presents a minimal native loading state, and the normal feature tree is not constructed. This prevents Dashboard, Accounts, Transactions, Budgets, More, and feature-local `.task` loaders from reading repositories before the multi-repository seed import reaches a terminal state.

On successful seeding the coordinator transitions to `ready` and `RootView` is created, so feature stores perform their usual initial loads against the fully seeded store.

On seed failure the coordinator transitions to a DEBUG developer-facing failure state with a retry action. The app does not silently continue into the normal feature UI after a failed opted-in seed import.

The loader:

- resolves explicit opt-in from process arguments/environment
- reads the configured local JSON file only when enabled
- decodes local DTOs
- maps DTOs into existing validated domain values
- checks that all supported repositories are empty
- persists via existing repository protocols
- saves in dependency-safe order

The seed JSON does not expose SwiftData models or `ModelContext`.

## Final Local Path

The selected local-only path is:

```text
Local/SeedData/cairn-seed.json
```

`.gitignore` ignores:

```text
Local/SeedData/
```

The directory and payload file are intentionally not committed.

## Final JSON Shape

Version 1 seed files use this top-level shape:

```json
{
  "schemaVersion": 1,
  "accounts": [
    {
      "id": "UUID",
      "name": "Everyday",
      "type": "checking",
      "currencyCode": "GBP",
      "openingBalance": 100.25
    }
  ],
  "categories": [
    {
      "id": "UUID",
      "name": "Groceries",
      "kind": "expense"
    }
  ],
  "transactions": [
    {
      "id": "UUID",
      "accountID": "UUID",
      "direction": "outflow",
      "amount": 12.34,
      "currencyCode": "GBP",
      "occurredAt": "2026-01-10T12:00:00Z",
      "categoryID": "UUID",
      "memo": "Market"
    }
  ],
  "budgets": [
    {
      "id": "UUID",
      "categoryID": "UUID",
      "limit": 500,
      "currencyCode": "GBP",
      "period": {
        "startDate": "2026-01-01T00:00:00Z",
        "endDate": "2026-02-01T00:00:00Z"
      }
    }
  ],
  "goals": [
    {
      "id": "UUID",
      "name": "Emergency Fund",
      "targetAmount": 1000,
      "targetCurrencyCode": "GBP",
      "currentAmount": 250,
      "currentCurrencyCode": "GBP",
      "targetDate": "2026-12-31T00:00:00Z"
    }
  ],
  "recurringTransactions": [
    {
      "id": "UUID",
      "accountID": "UUID",
      "direction": "outflow",
      "amount": 25,
      "currencyCode": "GBP",
      "frequency": "monthly",
      "startDate": "2026-01-01T09:00:00Z",
      "endDate": null,
      "memo": "Subscription"
    }
  ]
}
```

Supported enum spellings are the existing domain cases:

- account type: `checking`, `savings`, `creditCard`, `cash`, `investment`, `loan`
- category kind: `income`, `expense`
- transaction direction: `inflow`, `outflow`
- recurrence frequency: `daily`, `weekly`, `monthly`, `yearly`

Dates are ISO-8601 strings.

## Opt-In Mechanism

Seed loading is enabled only in DEBUG builds and only with either:

```text
--cairn-load-local-seed-data
```

or:

```text
CAIRN_LOAD_LOCAL_SEED_DATA=1
```

If opt-in is not present, the loader returns a skipped result and does not read the local file.

If the build is not a DEBUG build, the configuration resolves to a release-build skip even when opt-in flags are present.

With opt-in active, initial app content is gated until seed bootstrap succeeds or fails. This avoids an opted-in launch showing empty or partially imported data because feature stores loaded before seeding completed.

## Empty-Store Policy

The loader seeds only when all supported repositories are empty.

It checks:

- accounts
- categories
- transactions through the existing bounded date query
- budgets
- goals
- recurring transactions

If any data exists, it throws `LocalSeedDataError.storeNotEmpty` and performs no writes.

Repeated seed attempts therefore do not duplicate data.

## Developer Setup

To use local seed data on a developer machine:

1. Manually create `Local/SeedData/`.
2. Manually create `Local/SeedData/cairn-seed.json`.
3. Add a version 1 JSON payload matching the documented shape.
4. Launch the app in DEBUG with `--cairn-load-local-seed-data` or `CAIRN_LOAD_LOCAL_SEED_DATA=1`.

The seed payload is local financial data and must never be committed.

## Validation Performed

- `git -c core.fsmonitor=false diff --check`
- generic iOS Simulator build
- `LocalSeedDataLoaderTests` passed after implementation.
- `LocalSeedDataBootstrapCoordinatorTests` passed after adding startup gating.
- `git check-ignore -v Local/SeedData/cairn-seed.json`
- `git -c core.fsmonitor=false check-ignore -v Local/SeedData/cairn-seed.json`
- `git -c core.fsmonitor=false ls-files Local/SeedData/cairn-seed.json Local/SeedData`

The `ls-files` seed-payload check returned no tracked files.
