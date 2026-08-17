# Milestone 47: Error Recovery UX

Status: completed

## Objective

Establish consistent, actionable error and recovery behavior across Cairn's current UI without introducing a generic error framework.

Errors should explain what failed in plain language, preserve existing valid state, offer retry when meaningful, distinguish blocked actions from system failures, and avoid showing fake zero or empty financial data after failures.

## Audit Scope

Audit current error handling across:

- Dashboard
- Accounts
- Categories
- Transactions
- Budgets
- Goals
- Recurring Transactions
- DEBUG local seed bootstrap failure state
- app startup and composition

## Constraints

- Do not add a global error enum or app-wide error middleware.
- Do not expose SwiftData, `ModelContext`, stack traces, or internal type names in production user-facing text.
- Do not change domain, repository, or calculation contracts solely for UI consistency.
- Do not silently recreate, reset, or delete persistence stores.
- Keep seed-data failures developer-focused and DEBUG-only.
- Add focused tests only for changed behavior.

## Audit Findings

### Initial-Load Failure

Dashboard already has a full-screen unavailable state, but it does not offer Retry.

Accounts, Categories, Transactions, Budgets, Goals, and Recurring Transactions set `errorMessage` on load failure and clear loaded data. Because their `isEmpty` checks deliberately exclude error states, the views can fall through to an empty `List` with only a bottom error banner. This is not an actionable initial-load recovery state.

### Refresh/Retry Failure

No explicit refresh controls exist yet. Retrying the same initial load is meaningful when a load failure leaves no data visible.

### Save/Create/Edit Failure

Current editors keep the sheet open, preserve entered values, clear `isSaving`, and surface domain/parser/repository failures. This behavior is appropriate and should remain feature-owned.

### Delete Failure

Delete failures leave rows in place because rows are reloaded only after repository deletion succeeds. Errors surface through the existing feature error banner. This is acceptable for current scope.

### Referential-Integrity Block

Accounts and Categories distinguish blocked deletion from generic repository failure through feature-local error cases and specific messages. This should remain feature-local.

### Validation/Domain Failure

Editors map common parser and domain validation failures to focused text. They do not expose raw errors. This is acceptable.

### Calculation Failure

Accounts surface per-row balance calculation failures as unavailable state. Budgets, Goals, Recurring Transactions, and Dashboard treat calculation failure as load failure because derived values are required to truthfully render the feature. No fake zero values are substituted.

### Startup/Seed Failure

DEBUG local seed bootstrap already gates the root UI while loading, surfaces a developer-focused failure state, and offers Retry.

Production app startup still crashes with `fatalError` when `ModelContainer` creation fails. Safe automatic recovery is not currently possible because destructive reset is forbidden, but a minimal non-destructive app-level failure screen is feasible.

## Implementation Plan

- Add a small shared SwiftUI load-failure view using `ContentUnavailableView` and a native Retry button.
- Use that view for initial-load failures in Accounts, Categories, Transactions, Budgets, Goals, Recurring Transactions, and Dashboard.
- Keep bottom error banners for mutation failures when valid list data remains visible.
- Add small store-facing load-failure state helpers where needed so tests and views can distinguish initial-load failures from mutation failures.
- Replace app-startup persistence `fatalError` with a non-destructive startup failure state when `ModelContainer` cannot be created.
- Keep DEBUG seed bootstrap behavior unchanged except for any documentation required by this audit.

## Testing Plan

Add focused tests for changed behavior:

- initial load failure is represented as a load-failure state
- retrying after load failure invokes the load path again
- failed loads can recover when the underlying repository/calculation issue is resolved
- startup persistence failure maps to a non-destructive app-level failure state where practical

Do not duplicate repository/domain tests.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused tests for every changed feature

Do not run `/review`.

Do not stage or commit.

## Review Focus

- Initial-load failures are actionable and accessible.
- Retry reruns the failed load and does not fake success.
- Save/delete failure behavior remains state-preserving.
- Referential-integrity blocks remain distinct from system failures.
- Startup persistence failure is non-destructive.
- No generic enterprise error framework is introduced.

## Final Error UX Policy

Initial-load failures now use a native full-screen unavailable state with a Retry button when the feature has no valid data to show.

Mutation failures continue to use feature-local inline/banner messages when existing valid list data remains visible. This preserves context and avoids replacing valid state with an error screen after a failed save or delete.

Validation and domain failures remain editor-local. Editors keep entered values, clear saving state, and allow another save attempt.

Referential-integrity blocks remain distinct feature errors. Account and Category deletion blocks continue to explain that linked financial records prevent deletion.

Calculation failures are not converted to fake zero values. Features either mark the affected derived value unavailable or fail the load when the calculation is required to render truthful data.

## Recovery Behaviors

- Dashboard load failure shows `Dashboard Unavailable` with Retry.
- Accounts load failure shows `Accounts Unavailable` with Retry.
- Categories load failure shows `Categories Unavailable` with Retry.
- Transactions load failure shows `Transactions Unavailable` with Retry.
- Budgets load failure shows `Budgets Unavailable` with Retry.
- Goals load failure shows `Goals Unavailable` with Retry.
- Recurring Transactions load failure shows `Recurring Transactions Unavailable` with Retry.
- Retry calls the same feature load operation used by the initial `.task`.
- Save/edit failures keep the editor open and preserve entered values.
- Delete failures leave rows visible unless repository deletion succeeds.

## Startup Persistence Failure Policy

`ModelContainer` creation is now treated as an unrecoverable but non-destructive startup failure.

If the app cannot open its local data store, Cairn shows a minimal app-level failure screen explaining that the local data store could not be opened and that data was not reset or deleted.

No automatic reset, store deletion, migration fallback, or silent recreation behavior was added.

DEBUG local seed bootstrap remains developer-focused. It still gates root UI while opted-in seeding runs, surfaces seed failures, and offers Retry without changing production user UX.

## Intentionally Unchanged

- No generic app-wide error framework was introduced.
- Repository and domain error contracts were not broadened.
- Feature-specific validation messages remain feature-owned.
- Dashboard still uses a whole-dashboard error state rather than independent section errors because the current loaded snapshot model is intentionally simple.
- Existing bottom error banners remain for failed mutations when valid data is still visible.

## Validation Performed

- `git -c core.fsmonitor=false diff --check`
- generic iOS Simulator build
- focused tests for Dashboard, Accounts, Categories, Transactions, Budgets, Goals, Recurring Transactions, and app startup behavior
