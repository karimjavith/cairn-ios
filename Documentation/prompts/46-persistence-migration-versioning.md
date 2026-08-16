# Milestone 46: Persistence Migration Versioning

Status: completed

## Objective

Establish explicit SwiftData schema versioning and migration infrastructure for Cairn's current persistence model.

This milestone is infrastructure only. It must not add product behavior, invent historical schemas, or introduce destructive migration behavior.

## Current Schema

The first explicitly versioned Cairn schema is the current production persistence model as it exists at the start of this milestone.

It contains exactly:

- `AccountRecord`
- `TransactionRecord`
- `CategoryRecord`
- `BudgetRecord`
- `GoalRecord`
- `RecurringTransactionRecord`

This schema should be named `CairnSchemaV1`.

Do not modify persisted fields merely to justify migration work.

## SwiftData API Findings

The project targets iOS 17.0.

The installed SwiftData SDK exposes the needed iOS 17 APIs:

- `VersionedSchema`
- `SchemaMigrationPlan`
- `MigrationStage`
- `Schema(versionedSchema:)`
- `ModelContainer(for:migrationPlan:configurations:)`

The implementation should use these native SwiftData APIs directly.

## Versioned Schema

Define `CairnSchemaV1` under `App/Cairn/Persistence/`.

Requirements:

- conform to `VersionedSchema`
- use an explicit stable version identifier, `Schema.Version(1, 0, 0)`
- include exactly the six current SwiftData `@Model` record types
- avoid speculative future aliases, V0 schemas, V2 schemas, or model-field changes

Once shipped, `CairnSchemaV1` is immutable. Future schema changes must introduce a new schema version rather than editing V1.

## Migration Plan

Define a Cairn migration plan, `CairnSchemaMigrationPlan`, under `App/Cairn/Persistence/`.

For the current single-schema state:

- `schemas` contains only `CairnSchemaV1.self`
- `stages` is empty
- no fake lightweight stage is created
- no custom migration is created
- no historical V0 schema is invented

The plan exists so future V2 migrations can be added intentionally.

## Container Composition

Update the centralized `ModelContainer` composition in `CairnApp`.

The app must still have:

- one app-owned `ModelContainer`
- one app composition root
- no feature-created containers
- no exposed `ModelContext`
- no duplicate persistence ownership

`CairnApp` should build the container from `Schema(versionedSchema: CairnSchemaV1.self)` and pass `CairnSchemaMigrationPlan.self` to `ModelContainer`.

Preserve the existing DEBUG local seed-data bootstrap behavior.

## Compatibility Investigation

Before relying on the versioned schema, verify how SwiftData behaves when a store originally created with the current unversioned schema is opened with the equivalent explicit V1 schema and migration plan.

Where practical, add a focused integration test that:

- creates or loads a temporary store produced by the actual pre-versioning schema
- writes representative current records
- reopens the same store with `CairnSchemaV1` and `CairnSchemaMigrationPlan`
- fetches records through the versioned container
- confirms IDs and representative mapped domain values survive

If the installed SDK cannot open the pre-versioning store with the versioned schema, stop before shipping a destructive workaround.

Do not:

- delete existing stores
- reset data
- silently recreate the database
- introduce destructive fallback migration logic

## Migration Policy

Future schema evolution follows these rules:

- schema changes require a new explicit schema version
- shipped schema versions are immutable
- lightweight-compatible changes may use `MigrationStage.lightweight`
- custom migration stages are used only when data transformation is genuinely required
- destructive reset is not an acceptable production migration strategy
- migrations stay in persistence infrastructure, not feature code

Do not implement hypothetical future migrations in this milestone.

## Testing

Add focused persistence/versioning tests.

Cover at minimum:

- `CairnSchemaV1` contains all six intended models
- `CairnSchemaMigrationPlan` exposes the current schema
- centralized/versioned `ModelContainer` can be created
- current records can be inserted/fetched with the versioned container
- representative mappings still work
- a real pre-versioning store can be reopened with the versioned schema, if practical
- local seed-loader tests remain compatible where composition changes affect them

Do not duplicate every repository test.

## Architecture Constraints

Do not:

- put migration logic in feature code
- expose migration APIs to SwiftUI
- create generic persistence infrastructure beyond what SwiftData requires
- introduce third-party migration libraries
- create speculative V2/V3 schemas
- create a second production container

## Documentation Requirements

After implementation, update this document with:

- current schema version
- models included
- migration-plan design
- compatibility findings
- rules for future schema evolution
- validation performed
- deliberately deferred migration scenarios

Set status to `completed`.

Update `Documentation/prompts/README.md`.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused migration/versioning tests
4. directly affected persistence tests
5. directly affected local-seed tests if composition changed

Do not run the full `CairnTests` suite unless needed.

Do not run `/review`.

Do not stage or commit.

## Review Focus

- The versioned schema contains exactly the current persistence models.
- The migration plan does not invent fake history or destructive behavior.
- Existing central composition and seed bootstrap remain intact.
- Compatibility with the real current unversioned schema is tested or clearly documented.
- Persistence tests verify infrastructure without duplicating all repository behavior.

## Final Schema Version

The current persistence model is now explicitly represented by `CairnSchemaV1`.

`CairnSchemaV1` owns the frozen SwiftData model declarations as nested types:

```text
CairnSchemaV1.AccountRecord
CairnSchemaV1.BudgetRecord
CairnSchemaV1.CategoryRecord
CairnSchemaV1.GoalRecord
CairnSchemaV1.RecurringTransactionRecord
CairnSchemaV1.TransactionRecord
```

The app-facing record names currently resolve to V1 through typealiases:

```text
AccountRecord = CairnSchemaV1.AccountRecord
BudgetRecord = CairnSchemaV1.BudgetRecord
CategoryRecord = CairnSchemaV1.CategoryRecord
GoalRecord = CairnSchemaV1.GoalRecord
RecurringTransactionRecord = CairnSchemaV1.RecurringTransactionRecord
TransactionRecord = CairnSchemaV1.TransactionRecord
```

This keeps repositories and mapping extensions clean while making V1 structurally owned by the versioned schema.

Version:

```swift
Schema.Version(1, 0, 0)
```

Included models:

- `AccountRecord`
- `BudgetRecord`
- `CategoryRecord`
- `GoalRecord`
- `RecurringTransactionRecord`
- `TransactionRecord`

No persisted fields were changed.

No V1 model definition should be edited after this milestone ships.

## Final Migration Plan

`CairnSchemaMigrationPlan` is the app's explicit SwiftData migration plan.

It contains:

- `schemas`: `[CairnSchemaV1.self]`
- `stages`: `[]`

There is no V0, no fake historical schema, and no synthetic migration stage for the first explicit version.

Future V2 migrations should add a new immutable schema type and then add an appropriate lightweight or custom stage from V1 to V2.

## Final Container Composition

`CairnApp` still owns the single production `ModelContainer`.

The container is now created from:

```swift
Schema(versionedSchema: CairnSchemaV1.self)
```

and passes:

```swift
CairnSchemaMigrationPlan.self
```

to `ModelContainer`.

Feature views, feature stores, repositories, and the DEBUG local seed bootstrap still receive dependencies through the existing composition boundary. No feature owns migration logic or `ModelContext`.

## Compatibility Findings

The installed SwiftData SDK supports the required iOS 17 APIs:

- `VersionedSchema`
- `SchemaMigrationPlan`
- `MigrationStage`
- `Schema(versionedSchema:)`
- `ModelContainer(for:migrationPlan:configurations:)`

A focused integration test now uses a stored fixture produced by the actual pre-Milestone-46 source at commit `57572a2394ad64f3806c188e15b70d57a866237b`.

The fixture was generated by compiling that commit with the old top-level SwiftData model declarations and writing a store containing representative records for all six persisted aggregates. The committed fixture contains only synthetic data and includes the SQLite store, WAL, and SHM files required to represent the generated store exactly.

The current test copies that fixture to a temporary location, reopens it using `CairnSchemaV1` and `CairnSchemaMigrationPlan`, fetches all six record types, and reconstructs representative domain values.

That compatibility test passes. IDs, references, decimal strings, enum strings, optional values, and representative mapped domain values survive the transition from the real pre-versioning store to explicit V1 schema construction.

No destructive fallback, store reset, or database recreation behavior was added.

## Future Schema Rules

- New persisted fields, renamed fields, removed fields, or model changes require a new explicit schema version.
- Existing shipped schema versions are immutable.
- Future schema versions define their own distinct nested model classes.
- When V2 is introduced, current app-facing record aliases move to `CairnSchemaV2` while `CairnSchemaV1` remains untouched.
- Lightweight-compatible changes may use `MigrationStage.lightweight`.
- Custom stages are reserved for genuine data transformations.
- Destructive reset is not an acceptable production migration strategy.
- Migration code remains in persistence infrastructure.

## Deliberately Deferred

- No V2/V3 schema was introduced.
- No historical V0 schema was invented.
- No custom migration stage was added.
- No migration UI or feature-facing migration API was added.
- No broad repository-test duplication was added.

## Validation Performed

- `git -c core.fsmonitor=false diff --check`
- generic iOS Simulator build
- focused migration/versioning tests
- directly affected local seed-data tests

The focused compatibility test covers opening a real pre-versioning store fixture with the new explicit V1 migration plan.
