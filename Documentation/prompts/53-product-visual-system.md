# Milestone 53: Product Visual System and UX Direction

Status: completed

## Product Design Problem

Cairn's engineering foundation is complete, but the current UI still reads as default SwiftUI composition rather than a deliberate product experience.

The intended Cairn direction is modern, simple, slick, premium but restrained, finance-focused, highly legible, calm rather than decorative, and recognizably Cairn rather than stock SwiftUI.

The Dashboard currently illustrates the problem most clearly:

- oversized empty-state presentation
- repetitive large pale containers
- weak financial hierarchy
- excessive vertical space
- stock `GroupBox` and `List`-like appearance
- no strong financial focal point
- empty states that explain missing data without helping the user act
- little visual personality

Milestone 53 establishes the shared visual and interaction system that later milestones will apply feature-by-feature. It must not comprehensively redesign feature screens.

## Objective

Define and implement a small reusable Cairn presentation system sufficient to support the upcoming redesign.

The system should establish:

- typography hierarchy
- spacing rhythm
- screen layout conventions
- surfaces and cards
- financial-number presentation
- semantic status treatment
- buttons and actions
- section headers
- list and row conventions
- empty states
- loading and error states
- form and editor conventions
- progress presentation
- accessibility behavior
- light and dark mode behavior

## Constraints

- Write this design specification before substantial production changes.
- Do not redesign Dashboard, Accounts, Transactions, Budgets, Goals, Categories, Recurring Transactions, More, or editors in this milestone.
- Do not add new product features.
- Do not change domain, repository, persistence, migration, or business rules.
- Do not introduce a broad design-token framework.
- Do not create wrappers for `Text`, `Button`, `NavigationStack`, `List`, or `Form` without a concrete presentation reason.
- Do not add custom fonts.
- Do not add snapshot-testing dependencies.
- Do not add decorative animation, custom tab bars, neon styling, glassmorphism, excessive shadows, or nested cards.
- Preserve Milestone 48 accessibility rules and Milestone 47 recovery semantics.
- Do not run `/review`.
- Do not stage or commit.

## Design Principles

1. Financial information is primary.
   Amounts and financial status should receive stronger hierarchy than container decoration.

2. Reduce chrome.
   Do not put every section inside a large gray rounded rectangle. Cards should exist only where grouping materially improves comprehension.

3. Progressive disclosure.
   Primary information appears first. Secondary metadata is visually quieter.

4. Compact but breathable.
   Avoid both spreadsheet density and oversized empty vertical gaps.

5. Native interaction, custom presentation.
   Continue using native SwiftUI controls, navigation, forms, pickers, and buttons where they provide correct behavior.

6. Actionable empty states.
   Empty states should briefly explain what is missing and expose the logical next action when the current screen owns that action.

7. Financial semantics cannot depend on color.
   Inflow, outflow, overspending, completion, warnings, errors, and destructive actions must carry meaning through text, symbol, or accessibility semantics.

## Visual Hierarchy

Cairn's visual hierarchy should make the money obvious and the chrome quiet:

- Screen titles identify the current space.
- A hero financial value may anchor screens that have a clear primary amount.
- Section headings organize related content without becoming decorative banners.
- Rows prioritize the financial item identity and trailing amount or status.
- Metadata supports the primary value without competing with it.
- Empty, error, and loading states remain compact and actionable.

## Typography Roles

Use Dynamic Type-compatible system typography roles:

- screen title: `.largeTitle` or `.title`, bold, used by navigation/screen context
- hero financial value: `.largeTitle`, heavy/semibold, monospaced digits
- section title: `.headline`, semibold
- primary row value: `.headline` or `.body`, semibold where useful
- primary row label: `.body`, regular or semibold
- secondary metadata: `.subheadline`, secondary color
- status: `.subheadline` or `.caption`, semibold
- caption/helper text: `.caption` or `.footnote`, secondary color

Do not scale font sizes manually by viewport width. Prefer native text styles so Dynamic Type remains functional.

## Spacing Strategy

Use a small shared spacing scale:

- extra small: 4
- small: 8
- medium: 12
- large: 16
- extra large: 24
- section: 32

Spacing should be consistent enough to avoid unrelated magic numbers, but not expanded into a generic token framework.

## Surface and Card Rules

Use surfaces deliberately:

- Plain screen background is the default.
- Grouped sections use spacing, headings, and dividers before cards.
- Subtle cards are for summary groups, important focal areas, or repeated items that need containment.
- Dividers separate rows when row grouping matters.
- Inset rows can be used for dense financial lists.

Do not nest cards. Do not make every section a large rounded gray container.

## Buttons and Actions

Use native `Button` semantics.

Conventions:

- primary action: prominent filled button, concise label
- secondary action: plain or lightly bordered button
- destructive action: native destructive role, clear visible or accessible context
- compact/icon action: minimum tappable area, meaningful accessibility label

## Row Conventions

A Cairn financial row should support:

- leading context such as account, category, icon, or status symbol
- primary title/name
- secondary metadata such as date, account, category, frequency, or memo
- trailing amount, progress, or status

Rows should not all look like Settings rows. Use separators and surfaces intentionally.

## Financial-Value Conventions

Money presentation should:

- preserve locale and currency formatting
- use monospaced digits for scanability
- distinguish primary amounts from secondary metadata
- avoid relying on color alone for direction or status
- remain readable at large Dynamic Type sizes

Do not change `Money` semantics and do not add foreign-exchange behavior.

## Progress Conventions

Budgets and goals should share a semantic progress treatment:

- show the label/status in text
- show the primary amount or percentage separately from helper metadata
- do not visually clamp overspending in a misleading way
- communicate completion and overspending independently of color
- format goal percentages with locale-aware bounded precision, using whole percentages where possible and at most one fractional digit for non-whole values

## Empty, Error, and Loading Conventions

Empty states should be compact and actionable:

- concise title
- short explanation
- optional primary action when the screen owns the action
- optional restrained system symbol

Error states preserve Milestone 47 recovery behavior:

- error text remains visible
- retry action remains reachable
- no raw internal details leak to users

Loading should be calm and minimal. Do not add skeleton-loading infrastructure unless a future milestone proves the need.

## Form and Editor Conventions

Later editor redesigns should use:

- grouped logical sections
- visible labels
- clear amount hierarchy
- predictable Cancel and Save
- native date and picker controls
- inline helper or error text where useful

Do not redesign every editor in this milestone.

## Accessibility Rules

The visual system must preserve:

- Dynamic Type
- VoiceOver semantics
- native control behavior
- non-color-only financial meaning
- reasonable touch targets
- clear destructive action context

Avoid overcombining unrelated content into large accessibility elements.

## Dark-Mode Strategy

Use semantic system colors and materials that work in light and dark mode.

Do not hardcode colors that only work on white. Do not create a separate unrelated dark theme.

## Implementation Plan

Create minimal shared presentation primitives under `App/Cairn/Core/Presentation/`.

Candidate primitives:

- spacing scale
- typography helpers for financial values
- section heading
- subtle surface/card modifier
- compact empty state
- financial row
- semantic progress view
- DEBUG-only style reference view or previews using synthetic data

These primitives should be SwiftUI-native and composable.

## Reusable Primitives Implemented

Milestone 53 added a deliberately small shared presentation set under `App/Cairn/Core/Presentation/`:

- `CairnSpacing` for the small spacing scale.
- `CairnMoneyPresentation` for shared currency display and absolute amount display.
- `cairnHeroAmount()` and `cairnRowAmount()` text modifiers for high-priority financial values.
- `cairnSurface(_:)` for subtle/elevated grouping surfaces when a card materially helps comprehension.
- `CairnSectionHeading` for compact section hierarchy.
- `CairnEmptyStateView` for concise, optional-action empty states.
- `CairnFinancialRow` for financial list rows with leading context, title, metadata, trailing amount/status, and explicit accessibility label.
- `CairnProgressPresentation` and `CairnProgressSummaryView` for budget/goal-style progress semantics that expose textual status, bounded locale-aware percentage text, and accessibility labels.
- `CairnStyleReferenceView`, compiled only in DEBUG, to demonstrate the visual hierarchy, hero amount, section heading, row, surface, primary action, empty state, budget progress, and goal progress with synthetic data.

The primitives stay native SwiftUI composition rather than replacing `Text`, `Button`, `NavigationStack`, `List`, or `Form`.

## Testing Plan

Add focused tests only where meaningful.

Prioritize:

- financial formatting behavior if new formatting logic exists
- progress semantic labels
- overspending or completion semantics
- empty-state action behavior where testable

Do not introduce brittle visual snapshots or a large UI automation framework.

## Focused Tests Added

`CairnProgressPresentationTests` verifies:

- budget overspending uses textual "Overspent by" semantics and absolute amount display rather than a minus sign or color-only meaning
- normal budget progress uses textual remaining semantics
- completed goals expose "Complete" text and accessibility semantics
- goal percentages use bounded locale-aware formatting for whole, fractional, repeating-decimal, overshoot, and comma-decimal-locale cases

No snapshot tests or UI automation framework were added.

## Intentionally Deferred Feature Redesigns

Milestone 53 did not migrate Dashboard, Accounts, Transactions, Budgets, Goals, Categories, Recurring Transactions, More, or editors/forms.

Those screens remain functionally unchanged and will be redesigned in the roadmap below. The only app-code integration is the shared primitive set and DEBUG-only style reference view.

## Redesign Roadmap

- 54 — Dashboard redesign
- 55 — Accounts + Transactions redesign
- 56 — Budgets redesign
- 57 — Goals + Categories + Recurring Transactions + More redesign
- 58 — Forms/editors and interaction polish
- 59 — Empty/loading/error states and micro-interactions
- 60 — Full visual consistency audit + product dogfooding

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator Debug build
3. generic iOS Simulator Release build
4. focused tests for any presentation logic introduced

Do not run `/review`.

## Review Focus

- The visual system is small, reusable, and SwiftUI-native.
- The milestone establishes direction without redesigning feature screens.
- Financial information receives clear hierarchy.
- Empty, loading, error, row, surface, and progress conventions are documented.
- Accessibility and dark-mode behavior remain explicit.
- The DEBUG-only reference surface cannot become production navigation.
- Later redesign milestones have a clear roadmap.
