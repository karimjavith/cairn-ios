# Milestone 33: Recurring Transaction Scheduling

Status: completed

## Objective

Implement pure calendar-based recurrence scheduling for a valid `RecurringTransaction`.

Given a recurring transaction and a reference `Date`, scheduling must determine occurrence dates without creating transactions, saving state, mutating the recurring transaction, or depending on persistence, UI, notifications, timers, or repositories.

## Scope

- Add a focused pure finance scheduling type for `RecurringTransaction`.
- Support the existing recurrence frequencies only: daily, weekly, monthly, and yearly.
- Provide `nextOccurrence(after:)` with strict-after reference semantics.
- Provide a finite bounded occurrence query with explicit range boundaries.
- Use an explicitly injected `Calendar` for all recurrence calculations.
- Add deterministic unit tests for frequency behavior, boundaries, month-end behavior, leap years, time semantics, DST, and independence from non-scheduling transaction fields.

## Constraints

- Do not create `Transaction` values.
- Do not save generated occurrences.
- Do not mutate `RecurringTransaction`.
- Do not use repositories.
- Do not import SwiftData or SwiftUI.
- Do not send notifications, start timers, add background scheduling, or store last-run/next-run state.
- Do not add recurrence frequencies beyond the current domain values.
- Do not add custom recurrence rules, recurrence exceptions, business-day adjustment, generated occurrence persistence, missed-occurrence reconciliation, or automatic transaction posting.
- Do not depend implicitly on `Calendar.current`, `TimeZone.current`, or `Locale.current`.
- Do not implement recurrence by adding fixed numbers of seconds.
- Do not introduce a generic clock/calendar framework.

## Affected Files

- `Documentation/prompts/33-recurring-transaction-scheduling.md`
- `Documentation/prompts/README.md`
- `App/Cairn/Core/Finance/RecurringTransactionSchedule.swift`
- `App/CairnTests/Core/Finance/RecurringTransactionScheduleTests.swift`

## Key Design Decisions

- Place scheduling in `Core/Finance` because it composes shared finance domain types and is expected to become a foundation for later recurring-transaction generation.
- Model scheduling as a small immutable value initialized with one `RecurringTransaction` and an injected `Calendar`.
- Keep the API bounded: return the next occurrence after a reference date and occurrences inside a finite date range.
- Preserve `RecurringTransaction.startDate` as the first scheduled occurrence.
- Treat `RecurringTransaction.endDate` as an exclusive configured boundary: an occurrence is valid only when `occurrence < endDate`.
- Use calendar component arithmetic through the injected calendar rather than second-based intervals.
- For monthly and yearly invalid target dates, preserve the original intended day when possible and clamp to the last valid day of the target month when that day does not exist.
- Preserve the original local time components where the calendar can represent them.
- Keep scheduling independent from direction, amount, account, category, and memo fields.
- Use a small typed error only if Foundation cannot construct a required calendar occurrence.

## Date/Calendar Semantics

- Daily recurrence advances by one calendar day.
- Weekly recurrence advances by one calendar week.
- Monthly recurrence advances by one calendar month.
- Yearly recurrence advances by one calendar year.
- `startDate` is always the first scheduled occurrence and no occurrence may be before it.
- When `endDate` is nil, the recurrence has no configured final boundary.
- When `endDate` exists, scheduled occurrences must be strictly earlier than `endDate`; occurrences exactly equal to `endDate` are excluded.
- `occurrences(in:)` uses range start inclusive and range end exclusive semantics.
- All date arithmetic uses the injected `Calendar` and its configured `TimeZone`.
- Daily recurrence across daylight saving time transitions must preserve local wall-clock scheduling semantics rather than drift by fixed seconds.

## Validation Requirements

- `git -c core.fsmonitor=false diff --check`
- Generic iOS Simulator build
- `RecurringTransactionScheduleTests` on a concrete available iPhone simulator
- Existing `RecurringTransactionTests`
- `/review`
- Show `git status --short`
- Show the complete relevant diff

## Review Focus

- Calendar injection.
- No `Calendar.current` or `TimeZone.current` dependency.
- Start/end boundary correctness.
- `nextOccurrence(after:)` strict-after semantics.
- Monthly month-end behavior.
- Leap-year behavior.
- DST/calendar correctness.
- Deterministic range behavior.
- No seconds-based recurrence arithmetic.
- No persistence, repository, or UI leakage.
- Unnecessary abstraction.
- Suitability as a future foundation for automatic recurring-transaction generation.

## Commit Intent

One scoped commit adding pure recurring-transaction scheduling, focused deterministic tests, completed milestone documentation, and prompt README updates without staging or committing during implementation.
