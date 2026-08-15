# Milestone 36: App Navigation Shell

Status: completed

## Objective

Establish Cairn's production navigation shell and top-level feature entry points.

This milestone creates navigation structure only. It must not implement finished feature screens, data workflows, mock financial content, onboarding, settings, search, filters, charts, forms, CRUD, animations, or a custom design system.

## Existing Context

The application currently composes SwiftData ownership in `CairnApp` and renders a single `RootView`.

`CairnApp` owns the production `ModelContainer` and applies it to the scene with `.modelContainer(modelContainer)`. This milestone preserves that ownership and does not redesign dependency injection.

`RootView` is currently a static SwiftUI landing view. It is the correct app/UI composition boundary for the root navigation shell.

No feature UI files currently exist under `App/Cairn/Features`.

## Scope

Create a native iPhone-oriented SwiftUI shell with primary destinations for:

- Dashboard
- Accounts
- Transactions
- Budgets
- More

The `More` destination must expose navigation entry points for:

- Goals
- Categories
- Recurring Transactions

Goals lives under Cairn's explicit `More` destination so the iPhone tab bar stays within the native five-item limit and does not invoke UIKit's automatic system `More` tab.

Use native SwiftUI navigation:

- `TabView` for primary application destinations.
- `NavigationStack` within each top-level feature boundary where appropriate.
- `NavigationLink` for entries inside `More`.

## Out of Scope

Do not introduce:

- custom router frameworks
- coordinator frameworks
- global navigation singletons
- third-party navigation dependencies
- deep linking
- persisted navigation state
- repository construction inside feature views
- SwiftData access inside placeholder views
- view models for empty placeholders
- feature-specific state management

## Design

`RootView` will become the root shell. It will own only UI navigation composition:

- a deterministic list of primary tab destinations
- native tab labels
- root construction of each destination view

`AppTab` is app-owned root navigation metadata and belongs in `App/Cairn/App`.

Each top-level feature will own a minimal placeholder view in its feature folder under `App/Cairn/Features/<FeatureName>/Presentation`.

Placeholders will:

- provide a clear screen title
- use minimal native SwiftUI content
- avoid business logic and dependencies
- avoid mock financial data
- preserve Dynamic Type through standard `Text`, `ContentUnavailableView`, `List`, and native layout primitives

`More` will own a small list of secondary destinations. The list will be deterministic and backed by `MoreDestination`, feature-owned local navigation metadata that lives beside `MoreView` in `App/Cairn/Features/More/Presentation`.

## Testing Strategy

Add focused unit tests only for deterministic shell structure:

- root primary destinations are exactly Dashboard, Accounts, Transactions, Budgets, and More in order
- `More` destinations are exactly Goals, Categories, and Recurring Transactions in order
- `RootView` can be constructed

The tests should not introduce a navigation-testing abstraction or broad UI test workflow.

## Validation

Run only:

1. `git -c core.fsmonitor=false diff --check`
2. A generic iOS Simulator build
3. Focused tests added or affected by this milestone

Do not run `/review`.
Do not run the entire `CairnTests` suite unless unexpectedly required by broad impact.

## Completion Notes

## Final Design

`RootView` is now Cairn's production navigation shell. It composes a native SwiftUI `TabView` using deterministic `AppTab` metadata and wraps each primary destination in its own `NavigationStack`.

`AppTab` remains app-owned root navigation metadata.

Primary tabs are:

- Dashboard
- Accounts
- Transactions
- Budgets
- More

The primary iPhone `TabView` intentionally has five items. Goals remains a feature-owned destination, but is exposed from Cairn's `More` view to avoid the native iPhone tab-limit behavior that can otherwise collapse app-defined tabs behind UIKit's automatic system `More` tab.

`MoreView` owns the secondary navigation list and exposes deterministic entries for:

- Goals
- Categories
- Recurring Transactions

`MoreDestination` is feature-owned local navigation metadata in `App/Cairn/Features/More/Presentation`, because it only drives navigation inside `MoreView`.

Each destination is represented by a minimal SwiftUI placeholder view in its feature-owned `Presentation` folder.

## Affected Files

- `App/Cairn/App/AppTab.swift`
- `App/Cairn/App/RootView.swift`
- `App/Cairn/Features/Accounts/Presentation/AccountsView.swift`
- `App/Cairn/Features/Budgets/Presentation/BudgetsView.swift`
- `App/Cairn/Features/Categories/Presentation/CategoriesView.swift`
- `App/Cairn/Features/Dashboard/Presentation/DashboardView.swift`
- `App/Cairn/Features/Goals/Presentation/GoalsView.swift`
- `App/Cairn/Features/More/Presentation/MoreDestination.swift`
- `App/Cairn/Features/More/Presentation/MoreView.swift`
- `App/Cairn/Features/RecurringTransactions/Presentation/RecurringTransactionsView.swift`
- `App/Cairn/Features/Transactions/Presentation/TransactionsView.swift`
- `App/CairnTests/App/AppNavigationShellTests.swift`
- `Documentation/prompts/README.md`
- `Documentation/prompts/36-app-navigation-shell.md`

## Architectural Decisions

- Navigation composition remains in the app/UI composition layer.
- Root tab metadata is app-owned in `AppTab`.
- Local `More` navigation metadata is feature-owned in `MoreDestination`.
- Feature placeholders are independently owned by feature folders.
- No repositories, SwiftData contexts, view models, router frameworks, coordinator frameworks, singletons, third-party dependencies, deep links, or persisted navigation state were introduced.
- Existing SwiftData `ModelContainer` ownership in `CairnApp` is unchanged.
- Tests validate deterministic navigation metadata instead of introducing broad UI navigation testing.

## Validation Performed

- `xcodebuild -project App/Cairn.xcodeproj -scheme Cairn -destination generic/platform=iOS\ Simulator build`
- `xcodebuild -project App/Cairn.xcodeproj -scheme Cairn -destination platform=iOS\ Simulator,name=iPhone\ 17 -only-testing:CairnTests/AppNavigationShellTests test`
- `git -c core.fsmonitor=false diff --check`

## Intentionally Deferred Behavior

- finished feature screens
- financial data loading or mutation
- mock data
- charts
- forms
- CRUD
- search
- filters
- settings
- onboarding
- animations
- custom design system
- feature-specific state management
- deep linking
- persisted navigation state
