# Milestone Prompt Archive

## Purpose

This directory is Cairn's durable milestone-specification archive.

Milestone specs capture the engineering intent, scope, constraints, acceptance criteria, and review focus for completed and future Cairn milestones. They are specifications, not transcripts, and they should help future engineers and AI agents understand what each milestone was intended to achieve.

## Workflow

For every future milestone:

1. Create or update the milestone spec in this directory before implementation begins.
2. Implement against the spec.
3. Validate the change with the required build, test, and diff checks.
4. Review the change against the spec and the project standards.
5. Commit and push only after validation and review.
6. Mark the spec `completed` when the milestone lands.

## Rules

- Specs must remain aligned with `Documentation/ARCHITECTURE.md` and `Documentation/ENGINEERING.md`.
- Architecture changes must still be documented in `Documentation/ARCHITECTURE.md`.
- This folder does not replace ADRs, engineering standards, or architecture documentation.
- Milestone specs must not become implementation transcripts.
- Do not include terminal logs or conversational filler.
- Future AI agents must read the relevant milestone spec before making changes.

## Naming

Use zero-padded ordered filenames:

```text
NN-short-milestone-name.md
```

## Status

Use one of:

- `planned`
- `in-progress`
- `completed`

## Index

| Milestone | Status |
| --- | --- |
| [01-engineering-foundation.md](01-engineering-foundation.md) | completed |
| [02-architecture-structure-and-boundaries.md](02-architecture-structure-and-boundaries.md) | completed |
| [03-state-management-and-dependency-injection.md](03-state-management-and-dependency-injection.md) | completed |
| [04-application-composition.md](04-application-composition.md) | completed |
| [05-application-skeleton.md](05-application-skeleton.md) | completed |
| [06-money-domain.md](06-money-domain.md) | completed |
| [07-account-domain.md](07-account-domain.md) | completed |
| [08-transaction-domain.md](08-transaction-domain.md) | completed |
| [09-category-domain.md](09-category-domain.md) | completed |
| [10-budget-domain.md](10-budget-domain.md) | completed |
| [11-goal-domain.md](11-goal-domain.md) | completed |
| [12-recurring-transaction-domain.md](12-recurring-transaction-domain.md) | completed |
| [13-domain-consistency-audit.md](13-domain-consistency-audit.md) | completed |
| [14-repository-contracts.md](14-repository-contracts.md) | completed |
| [15-account-persistence-model.md](15-account-persistence-model.md) | completed |
| [16-account-repository.md](16-account-repository.md) | completed |
| [17-transaction-persistence-model.md](17-transaction-persistence-model.md) | completed |
| [18-transaction-repository.md](18-transaction-repository.md) | completed |
| [19-category-persistence-model.md](19-category-persistence-model.md) | completed |
| [20-category-repository.md](20-category-repository.md) | completed |
| [21-budget-persistence-model.md](21-budget-persistence-model.md) | completed |
| [22-strict-decimal-persistence-consistency.md](22-strict-decimal-persistence-consistency.md) | completed |
| [23-budget-repository.md](23-budget-repository.md) | completed |
| [24-goal-persistence-model.md](24-goal-persistence-model.md) | completed |
| [25-goal-repository.md](25-goal-repository.md) | completed |
| [26-recurring-transaction-persistence-model.md](26-recurring-transaction-persistence-model.md) | completed |
| [27-recurring-transaction-repository.md](27-recurring-transaction-repository.md) | completed |
| [28-persistence-consistency-audit.md](28-persistence-consistency-audit.md) | completed |
| [29-create-transaction-workflow.md](29-create-transaction-workflow.md) | completed |
| [30-account-balance-aggregation.md](30-account-balance-aggregation.md) | completed |
| [31a-transaction-category-assignment.md](31a-transaction-category-assignment.md) | completed |
| [31-budget-progress.md](31-budget-progress.md) | completed |
| [32-goal-progress.md](32-goal-progress.md) | completed |
| [33-recurring-transaction-scheduling.md](33-recurring-transaction-scheduling.md) | completed |
| [34a-bounded-transaction-date-query.md](34a-bounded-transaction-date-query.md) | completed |
| [34-cash-flow-summary.md](34-cash-flow-summary.md) | completed |
| [35-application-workflow-consistency-audit.md](35-application-workflow-consistency-audit.md) | completed |
| [36-app-navigation-shell.md](36-app-navigation-shell.md) | completed |
| [37-accounts-feature.md](37-accounts-feature.md) | completed |
| [38-categories-feature.md](38-categories-feature.md) | completed |
| [39-transactions-feature.md](39-transactions-feature.md) | completed |
| [40-budgets-feature.md](40-budgets-feature.md) | completed |
| [41-goals-feature.md](41-goals-feature.md) | completed |
| [42-recurring-transactions-feature.md](42-recurring-transactions-feature.md) | completed |
| [43-dashboard.md](43-dashboard.md) | completed |
| [44-feature-ui-integration-audit.md](44-feature-ui-integration-audit.md) | completed |
| [45-local-seed-data-integration.md](45-local-seed-data-integration.md) | completed |
| [46-persistence-migration-versioning.md](46-persistence-migration-versioning.md) | completed |
