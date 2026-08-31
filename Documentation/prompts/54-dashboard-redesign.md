# Milestone 54: Dashboard Redesign

Status: in-progress

## Product Direction

The first Milestone 54 Dashboard visual pass was rejected by the product owner.

The locked direction for Cairn is:

```text
Editorial & Minimal - Purple
```

This milestone now implements the Dashboard as the first concrete product screen under the approved Cairn product language. The authoritative system spec is `Documentation/PRODUCT_DESIGN.md`.

## Preserve Or Discard Current Work

Classification of the previous uncommitted Milestone 54 work:

- Reusable non-visual behavior:
  - App-owned selected tab state in `RootView`.
  - One-shot Add Account request from Dashboard into Accounts.
- Reusable presentation logic:
  - `DashboardHeroPresentation` for truthful net-worth and mixed-currency display decisions.
  - No fake zero hero for empty Dashboard data.
- Rejected visual composition:
  - Top-heavy generic `Start with an account` empty state.
  - Outlined/elevated rectangle as the primary visual object.
  - Default-feeling composition with too much accidental blankness.
  - Generic finance copy that did not establish the approved editorial purple direction.
- Tests that remain valid:
  - Empty Dashboard does not create fake zero net worth.
  - Single-currency hero uses truthful net worth.
  - Mixed-currency hero keeps totals separated.
  - Existing Dashboard correctness tests.
- Documentation that must be rewritten:
  - Milestone 54 remains `in-progress`.
  - The final visual acceptance cannot be claimed until product-owner approval.

## Objective

Redesign only the Dashboard against `Documentation/PRODUCT_DESIGN.md`.

The redesigned Dashboard must feel:

- calm
- premium
- editorial
- minimal
- finance-first
- warm near-white in light mode
- deep aubergine/plum in identity
- restrained in surface use
- compact but breathable

Do not change Dashboard business logic unless a concrete presentation blocker is found.

## Dashboard States

### Completely Empty

Implement an intentional editorial first-run Dashboard:

- small Cairn stacked-stone logo mark near the top leading edge
- editorial hero statement: `Your money,\nin one place.`
- supporting sentence: `Add your first account to see your balances, track spending, and reach your goals.`
- secondary stacked-stone/cairn motif derived from the logo identity
- one strong plum `Add account` action
- subtle customer-facing privacy reassurance: `Your data stays on this device.`
- no empty Accounts/Cash Flow/Budgets/Goals cards

The screen should use a consistent 24-point page grid, avoid duplicate textual Cairn branding, and avoid accidental dead areas.

### Account Exists, No Transactions

Move away from onboarding:

- show truthful financial position
- show account/currency context
- prompt the user to record first activity
- do not show the first-run hero as the dominant element

### Populated Single Currency

Show:

- net worth hero
- account count/context
- inflow
- outflow
- net
- compact budget progress when present
- compact goal progress when present
- recent activity

### Multiple Currencies

Never sum unlike currencies. Show concise per-currency financial positions.

### No Budgets Or Goals

Do not show giant empty sections. Use compact contextual invitations or omit the section when that is calmer.

### Loading And Failure

Loading remains minimal and calm.

Failures preserve Milestone 47 retry semantics while using the Cairn visual language.

## Visual Implementation Rules

- Use `CairnColor` semantic roles.
- Use plum for primary action and identity, not system blue.
- Use green/red only for financial semantics.
- Default to no card.
- Use lavender surfaces only where grouping helps comprehension.
- Avoid nested cards, heavy outlines, shadows, gradients, glassmorphism, neon styling, and custom tab bars.
- Use SF Symbols.
- Preserve Dynamic Type and VoiceOver semantics.

## Navigation

Dashboard remains the root Dashboard tab.

The first-run Add Account action may use app-owned tab selection plus a one-shot create-account request. This preserves feature-owned local navigation and avoids a global router.

## Testing

Preserve/update focused tests for:

- no fake zero net worth
- single currency
- multiple currencies
- Add Account journey where practical
- deterministic section behavior
- existing Dashboard correctness

Do not add snapshot dependencies.

## Visual Validation

Before stopping:

1. Capture empty Dashboard in an iPhone simulator.
2. Create representative synthetic local data using DEBUG/local tooling without committing a seed payload.
3. Capture populated Dashboard.
4. Capture dark-mode populated Dashboard if practical.

The product owner must approve screenshots before this milestone can be marked completed.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator Debug build
3. generic iOS Simulator Release build
4. focused Dashboard tests
5. `AppNavigationShellTests` if navigation wiring changed
6. empty-state simulator capture
7. populated-state simulator capture
8. dark-mode capture if practical

Do not run `/review`.

Do not stage or commit.

## Acceptance Gate

Milestone 54 remains `in-progress` until:

- engineering validation passes
- manual `/review` passes
- product-owner visual approval is granted from simulator screenshots
