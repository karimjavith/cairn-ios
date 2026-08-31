# Cairn Product Design

## Direction

Cairn's approved product direction is:

```text
Editorial & Minimal - Purple
```

Cairn should feel like a calm, premium, local-first personal-finance product. The interface is finance-first, editorial in hierarchy, compact but breathable, and recognizably Cairn through a warm near-white canvas, deep aubergine/plum identity color, restrained pale-lavender surfaces, and strong financial-number typography.

The design must never become ornamental fintech styling. Green and red are reserved for financial/status semantics, not brand decoration.

## Product Principles

- Financial information before chrome: amounts, position, status, and next action matter more than containers.
- Editorial hierarchy: use scale and composition deliberately, especially for first-run and hero moments.
- Calm confidence: avoid noisy decoration, gratuitous animation, heavy shadows, neon color, and glass effects.
- Progressive disclosure: primary information first; secondary context remains quieter.
- Compact but breathable: avoid spreadsheet density and avoid accidental blank space.
- Actionable states: empty and error states should help the user move forward.
- Native interaction: keep SwiftUI navigation, buttons, sheets, pickers, fields, toggles, menus, and system behaviors.
- Accessibility by construction: Dynamic Type, VoiceOver, non-color-only semantics, and touch targets are baseline requirements.

## Color System

Use semantic roles in SwiftUI rather than scattering color literals through feature views.

Roles:

- `canvas/background`: warm near-white in light mode; warm near-black plum in dark mode.
- `primary text`: high-contrast ink/plum-black.
- `secondary text`: quieter contextual text.
- `tertiary text`: low-emphasis metadata.
- `brand/accent plum`: Cairn identity color for primary actions, focused labels, and selected emphasis.
- `lavender stone`: tonal lavender/plum roles used by the Cairn stacked-stone mark asset and subtle first-run landscape ground.
- `subtle lavender surface`: low-chrome grouping surface.
- `elevated/focused surface`: rare focused content surface.
- `separator`: quiet row separation.
- `positive`: inflow, surplus, good status.
- `negative`: outflow, overspending, destructive financial status.
- `warning`: near-limit or caution states.
- `neutral`: inactive or balanced state.

Light mode uses a warm near-white canvas and deep plum accent. Dark mode should feel intentional: deep aubergine canvas, softened lavender/plum surfaces, and accessible text contrast. Do not simply invert light colors.

Green and red must communicate financial/status semantics only. Do not use them as brand color.

## Typography

Prefer SF Pro/system typography for functional UI.

Roles:

- Product identity: the Cairn stacked-stone logo mark should replace textual Cairn branding where practical, especially in first-run and editorial compositions. The mark uses one bundled vector asset with four organic, asymmetric stones, widest at bottom and smallest at top, with a strong plum/lavender silhouette at compact and display sizes.
- Large first-run artwork uses `Documentation/design/cairn-approved-artwork.png` as the authoritative source; `CairnLogoMark` remains the simplified small-size mark.
- Editorial hero statement: carefully used serif/system display treatment for onboarding and rare hero moments. First-run hero scale should be about 38-40 pt at default Dynamic Type, semibold, leading aligned, and limited to two deliberate lines.
- Hero financial amount: large system type, semibold/heavy, monospaced digits.
- Screen title: native navigation title unless a screen has an intentional custom editorial hero.
- Section title: headline, semibold.
- Primary row text: body, medium/semibold where useful.
- Secondary metadata: subheadline, secondary color.
- Amount: headline/body, semibold, monospaced digits.
- Caption/helper: caption or footnote.
- Button/action: body, semibold.

If an editorial display treatment is needed, use Apple/system-provided serif or rounded designs. Do not add third-party font files.

Dynamic Type remains mandatory. Avoid fixed heights and viewport-scaled fonts.

## Spacing And Layout

Use a small shared scale:

- compact: 4
- row: 8
- internal: 12
- page inset: 24
- section: 28
- hero: 36

Layouts should feel intentional:

- Dashboard and feature roots use a warm canvas.
- Page horizontal inset should usually be 24 points.
- Major sections should be visually separated by spacing, not default cards.
- Rows should align amounts consistently and preserve readable wrapping.
- Hero moments may use more vertical space, but should be composed with flexible rhythm rather than accidental dead areas. First-run CTAs and reassurance text must reserve visible space above the native tab bar.

## Surfaces

Default to no container.

Use:

- No container: normal sections, rows, headings, hero text.
- Subtle grouped surface: related metrics or progress items where grouping improves comprehension.
- Elevated/focused surface: first-run action panel or a single primary summary block.
- Divider: row separation when lists need rhythm.

Avoid nested cards. Avoid outlined rectangles as the primary layout system. Avoid large card stacks.

## Buttons

Buttons stay native `Button` controls.

- Primary: plum-filled, capsule or softly rounded, clear label, approximately 50-54-point height for main actions. Main first-run actions should be centered and deliberate rather than full-width by default.
- Secondary: lavender/quiet surface or plain plum text.
- Destructive: native destructive role plus clear text.
- Icon/compact: SF Symbol, meaningful accessibility label, practical tappable area.

Primary actions should not look like default blue SwiftUI buttons.

## Financial Values

Financial values should be the strongest visual elements where they represent the user's position.

Rules:

- Hero amount: prominent, monospaced digits, clear label and currency context.
- Regular amount: semibold, monospaced digits.
- Positive/negative treatment: text or symbol must carry meaning; color can reinforce.
- Currency context: visible where ambiguity exists.
- Mixed currencies: never fabricate converted totals.
- Zero: only show zero when it is a truthful loaded value; never use fake zero as placeholder.
- Unavailable: show explicit unavailable/pending wording.

## Row System

A standard Cairn financial row may include:

- optional semantic icon
- title
- secondary context
- trailing amount/status
- optional disclosure/navigation affordance

Rows should not resemble Settings by default. They should prioritize financial identity, context, and amount.

## Progress

Budget progress:

- show category identity
- show spent/limit or remaining/overspent
- show near-limit and overspent as text, not color alone
- do not visually clamp overspending in a misleading way

Goal progress:

- show goal name
- show percentage/completion with bounded formatting
- show saved/target or remaining context
- completion and over-target states must be textual

## Navigation

Keep the five-tab architecture:

- Dashboard
- Accounts
- Transactions
- Budgets
- More

Feature-owned local navigation stays inside its feature. Sheets/editors are used for add/edit flows where already established. Dashboard may use app-owned tab selection for root-tab actions such as Add Account or See All. Native tab selection uses the Cairn plum brand tint. Do not add a custom router or custom tab bar unless a future architecture milestone proves it necessary.

## First-Run Journey

The intended journey:

1. Add account.
2. Record activity.
3. Understand financial position.
4. Create budgets/goals.
5. Maintain.

Empty states should advance this journey rather than repeat missing-data messages.

## Dashboard States

### Completely Empty

Use an editorial/minimal composition:

- small Cairn stacked-stone logo mark near the top leading edge
- editorial hero: `Your money,\nin one place.`
- supporting sentence: `Add your first account to see your balances, track spending, and reach your goals.`
- restrained cairn/stacked-stone motif derived from the logo identity and integrated into a subtle lavender ground/landscape treatment
- one strong plum `Add account` action
- customer-facing privacy reassurance: `Your data stays on this device.`
- no empty Accounts/Cash Flow/Budgets/Goals cards

The composition should intentionally occupy the screen without creating accidental blankness. A short plum editorial rule sits below the hero. Do not repeat textual Cairn branding in the first-run composition when the logo mark already provides identity.

### Account Exists, No Transactions

Transition away from onboarding:

- show truthful balance/financial position
- prompt the user to record first activity
- do not keep the first-run editorial hero dominant

### Populated Single Currency

Show:

- net worth hero
- account count/context
- income
- spending
- net
- compact budgets if available
- goals if useful
- recent activity

Only add visualization when current data truthfully supports it.

### Multiple Currencies

Never sum unlike currencies. Show concise per-currency positions.

### No Budgets Or Goals

Do not show giant empty sections. Use compact contextual invitations or omit sections.

### Loading

Minimal and calm.

### Failure

Preserve retry semantics while matching Cairn's visual language.

## Accounts UX Spec

Empty:

- clear prompt to add first account
- one primary Add Account action

Populated:

- per-currency summary when needed
- account rows with name, type, current balance
- no fake combined total across currencies

Detail:

- balance and account identity first
- actions for edit/delete remain clear

Add/Edit:

- visible labels
- native fields/pickers
- save/cancel actions

Deletion/integrity:

- destructive confirmations remain explicit
- blocked deletion explains referenced data.

## Transactions UX Spec

Empty:

- explain that activity creates the financial picture
- primary add action where owned by the screen

Populated:

- chronological grouping when implemented
- income/expense text semantics
- row title/context/amount/date
- optional search/filter only when functionality exists

Add/Edit/Delete:

- native editor controls
- amount and direction clearly labeled
- destructive delete confirmation.

## Budgets UX Spec

Empty:

- explain budgets as category spending boundaries
- prompt creation after categories/accounts exist

Populated:

- category identity
- spent/limit/remaining
- near-limit and overspent states
- compact progress treatment

Add/Edit:

- category, limit, period, and validation remain explicit.

## Goals UX Spec

Empty:

- explain savings target tracking
- prompt creating first goal

Populated:

- progress, saved/target, remaining
- completed and over-target states textual

Add/Edit:

- amount entry, target date, and validation are clear.

## Categories UX Spec

List:

- semantic income/expense identity
- compact row treatment

Empty:

- explain categories as transaction organization

Add/Edit:

- visible labels and native controls

Referenced-delete failure:

- explain why deletion is blocked and what references exist where possible.

## Recurring Transactions UX Spec

Empty:

- explain scheduled recurring activity

Populated:

- recurrence description
- next occurrence
- amount/account context

Add/Edit/Delete:

- native schedule controls
- bounded recurrence semantics
- explicit destructive confirmation.

## More UX Spec

More contains secondary feature areas without feeling arbitrary:

- Goals
- Categories
- Recurring Transactions
- Settings/About only when supported

Rows should use clear labels and SF Symbols. More should not become a dumping ground for primary financial tasks.

## Forms And Editors

Use native sheets or navigation presentation already established by the feature.

Conventions:

- clear title
- Cancel and Save
- visible field labels
- grouped logical sections
- native amount, date, picker, toggle, and text controls
- inline helper/error text where useful
- keyboard behavior follows iOS norms
- validation should be visible and specific without exposing internals.

## System States

Empty:

- compact, helpful, action-oriented

Loading:

- minimal progress indicator and text

Retryable failure:

- visible message and Retry button

Validation failure:

- inline or clearly associated with the relevant control

Destructive confirmation:

- native confirmation with object context

Blocked deletion:

- explains the integrity constraint

Startup failure:

- non-destructive and retryable where possible.

## Dark Mode

Dark mode uses deep aubergine/near-black canvas, softened lavender surfaces, plum identity accents, and sufficient text contrast. It should feel like Cairn, not a simple inversion.

Financial semantic colors remain green/red/warning and must pass contrast checks in context.

## Accessibility

Preserve:

- Dynamic Type
- VoiceOver labels
- non-color-only financial semantics
- practical 44-point touch targets
- Reduce Motion compatibility
- sufficient contrast
- native control behavior

Do not overcombine unrelated content into huge accessibility elements.

## Motion

Motion should be restrained and purposeful:

- no decorative animation infrastructure now
- respect Reduce Motion
- use default native transitions unless a future milestone justifies more.

## Product Acceptance Gate

No redesigned feature milestone is complete solely because:

- it builds
- tests pass
- `/review` is clean

Each redesigned feature also requires product-owner visual approval in the simulator.
