# Milestone 48: Accessibility Audit

Status: completed

## Objective

Perform a focused accessibility audit of Cairn's current SwiftUI interface and fix real accessibility barriers without redesigning the visual system or changing feature architecture.

The audit covers:

- app navigation shell
- Dashboard
- Accounts
- Categories
- Transactions
- Budgets
- Goals
- Recurring Transactions
- More
- editors and forms
- detail views
- confirmation dialogs
- loading, error, and empty states

## Constraints

- Audit before modifying production code.
- Fix meaningful accessibility barriers only.
- Do not modify code merely for stylistic accessibility uniformity.
- Keep accessibility behavior in presentation.
- Do not change domain rules, repository contracts, persistence models, or calculations.
- Do not add a global accessibility abstraction layer.
- Do not introduce custom focus-management infrastructure.
- Do not add decorative animation or redesign the visual system.
- Do not add accessibility identifiers broadly; add them only for genuine test targeting needs.
- Do not confuse `accessibilityIdentifier` with VoiceOver labels.
- Do not run `/review`.
- Do not stage or commit.

## Audit Method

Inspect the current UI implementation and focused tests before changing production code.

Categorize findings as:

- VoiceOver issue
- semantic labeling issue
- Dynamic Type issue
- color-only communication
- touch-target/control issue
- navigation/focus issue
- destructive-action issue
- meaningful test gap
- harmless implementation difference

Only fix findings that materially affect VoiceOver use, semantic meaning, Dynamic Type support, independent communication of financial state, control reachability, destructive-action clarity, or recovery from errors.

## VoiceOver Review

Verify:

- every actionable control has a useful accessible name
- icon-only buttons have accessibility labels
- financial rows expose coherent meaning without becoming giant unrelated accessibility elements
- labels do not redundantly repeat visible text where the native control already exposes it well
- amounts, direction, status, and context are understandable
- editor fields are properly labeled
- retry and error controls are understandable
- destructive actions clearly communicate intent

## Financial Semantics Review

Important states must not be communicated by color alone.

Audit:

- inflow versus outflow
- positive versus negative cash flow or balance
- budget overspending
- goal completion
- errors and warnings
- destructive actions

Text, symbols, native semantics, or accessibility labels must carry the meaning independently of color.

## Dynamic Type Review

Audit for larger text sizes:

- fixed heights that clip text
- hard-coded frames that constrain labels
- horizontal layouts that become unusable
- truncated financial labels where wrapping is appropriate
- editors and forms that fail with large content sizes

Prefer native adaptive SwiftUI layout. Do not redesign feature layouts unless a real barrier is found.

## Touch Target and Control Review

Verify:

- native buttons, toggles, navigation links, pickers, text fields, date pickers, and menus are used where suitable
- small icon controls have reasonable tappable areas
- custom gesture-only controls are not introduced where native controls are suitable

## Navigation and Focus Review

Verify:

- navigation titles exist
- sheets and editors have clear close, cancel, and save actions
- destructive confirmations remain accessible
- error and retry states do not create dead ends
- hidden duplicate controls do not confuse assistive technologies

## Forms Review

Audit create and edit forms for:

- meaningful field labels
- amount field semantics
- currency controls
- date controls
- optional-value controls
- validation and error presentation

Placeholder text must not be the only accessible label.

## Error, Empty, and Loading State Review

Verify Milestone 47 recovery UX remains accessible:

- retry buttons are labeled
- error text is exposed
- loading states are understandable
- empty states explain what the user can do

## Reduce Motion and Visual Effects Review

If Cairn has nonessential animations or transitions, ensure they do not create obvious accessibility problems.

If no meaningful animation is present, document that no production change was required.

## Testing Plan

Add focused accessibility regression tests where practical.

Prefer semantic and state tests over brittle visual snapshots.

Candidate coverage:

- icon-only actions expose labels
- financial direction or status is represented textually
- retry and error actions have useful labels
- key editor controls have explicit labels
- navigation structure remains reachable

If SwiftUI accessibility properties cannot be reliably unit-tested in the current setup, document the limitation instead of adding brittle UI automation.

Do not add a large UI automation framework.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator build
3. focused tests for changed features
4. `AppNavigationShellTests` if navigation or accessibility changes affect root navigation

Do not run the full `CairnTests` suite unless necessary.

## Review Focus

- Accessibility changes are meaningful and scoped.
- VoiceOver labels improve understanding without excessive grouping.
- Financial states remain understandable without color.
- Dynamic Type is not blocked by avoidable fixed constraints.
- Native controls remain native.
- Error, retry, loading, and empty states remain reachable and understandable.
- Destructive actions clearly communicate what will happen.
- Presentation owns accessibility behavior.
- No domain, persistence, repository, or architecture changes were introduced.

## Final Documentation Requirements

After implementation, update this file with an `Audit Findings` section covering:

- issues found
- fixes made
- areas verified with no changes
- limitations or deferred checks

Set status to `completed`.

Update `Documentation/prompts/README.md` consistently.

## Audit Findings

### VoiceOver Issue

- Budgets, Goals, Transactions, and Recurring Transactions used generic destructive action labels in several swipe actions, detail views, or confirmation flows. For users navigating by VoiceOver actions, "Delete Budget" or "Delete Transaction" could lose the item context.
- Budget rows exposed negative remaining amounts as data, but did not clearly communicate the overspent state in VoiceOver text.

### Semantic Labeling Issue

- Budget overspending was shown as a negative "Remaining" amount. This was truthful but semantically weak because the state was not named.
- Transactions and Recurring Transactions already exposed direction, amount, account, date or frequency, and memo in row accessibility labels.
- Accounts and Categories already exposed useful row labels and contextual delete labels.

### Dynamic Type Issue

- No blocking Dynamic Type issue was found in the audited scope.
- Current feature lists, details, and editors use native SwiftUI `List`, `Form`, `LabeledContent`, `TextField`, `Picker`, `DatePicker`, and `Toggle` controls without fixed row heights.
- Existing memo previews intentionally use bounded line limits. That was left unchanged because they are secondary content and full memo text remains available in detail views.

### Color-Only Communication

- Budget overspending needed a textual state independent of any amount styling. Budget list rows, budget detail, Dashboard budgets, and budget row accessibility text now use "Overspent" / "overspent by" when remaining budget is negative.
- Inflow and outflow, goal completion, loading, errors, and destructive actions were already represented with text or native semantics rather than color alone.

### Touch-Target/Control Issue

- No meaningful touch-target issue was found.
- Primary actions use native `Button`, `NavigationLink`, toolbar items, and swipe actions.
- Editors use native form controls rather than custom gesture-only controls.

### Navigation/Focus Issue

- No navigation/focus blocker was found.
- Root navigation still has five primary tabs.
- More still links to Goals, Categories, and Recurring Transactions.
- Feature screens and editor sheets have navigation titles, and editor sheets retain clear Cancel and Save actions.
- Error retry states remain reachable through native `ContentUnavailableView` actions.

### Destructive-Action Issue

- Budget, Goal, Transaction, and Recurring Transaction destructive labels and confirmation messages were tightened to include the affected item context.
- Accounts and Categories already included the deleted account or category name and were left unchanged.

### Meaningful Test Gap

- Added focused regression coverage for budget overspending presentation semantics.
- SwiftUI's generated VoiceOver tree is not directly tested in the current unit-test setup. The stable formatter text backing the visible and accessible budget state is tested instead.
- No large UI automation framework was added.

### Harmless Implementation Difference

- Dashboard continues to combine each small financial summary row with `.accessibilityElement(children: .combine)`. This is appropriate for concise related values and does not overcombine unrelated content.
- Some delete controls keep compact visible text such as "Delete Transaction" while their accessibility labels and confirmation messages carry richer item context. This preserves native compact destructive controls without losing assistive context.
- No meaningful animation or custom transition was found, so no reduced-motion production change was required.

## Fixes Made

- Added budget presentation helpers that name negative remaining budget as "Overspent" and expose "overspent by ..." accessibility text without relying on a minus sign or color.
- Updated budget list rows and budget detail to show "Overspent" instead of "Remaining" when a budget is over limit.
- Updated Dashboard budget summaries to show "Overspent" for negative remaining budget.
- Added item-specific destructive context for Budget and Goal delete actions.
- Added transaction-specific and recurring-transaction-specific context to destructive accessibility labels and confirmation messages.
- Added focused formatter tests for budget and dashboard overspending semantics.

## Areas Verified With No Changes

- App navigation shell and More navigation remain native and reachable.
- Dashboard sections expose financial direction, cash-flow labels, budget values, goal completion status, and recent transaction direction as text.
- Accounts rows already expose account name, account type, and balance state; unavailable balances use semantic text.
- Categories rows already expose category name and kind.
- Transactions and Recurring Transactions rows already expose inflow/outflow direction text and contextual row labels.
- Editors/forms already use native labeled fields and controls; placeholders are not the only accessible labels.
- Loading states use labeled `ProgressView` where feature loading occurs.
- Milestone 47 load-failure states use `LoadFailureView` with labeled Retry controls.
- Empty and not-found states use native `ContentUnavailableView` with explanatory text.

## Limitations and Deferred Checks

- Manual VoiceOver rotor behavior and extra-large Dynamic Type layout should still be spot-checked on device or Simulator during manual review because the current test setup does not introspect SwiftUI's accessibility tree reliably.
- No accessibility identifiers were added because the current focused tests did not require new stable UI automation targets.
