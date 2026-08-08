# 05 Application Skeleton

Status: completed

## Objective

Establish the initial buildable iOS app skeleton under `App/` with a minimal SwiftUI entry point and root view.

## Scope

- Keep the Xcode project under `App/Cairn.xcodeproj`.
- Provide a minimal app entry point and root view.
- Preserve the documented repository layout.

## Constraints

- Do not implement product features.
- Do not add speculative folders beyond the agreed layout.
- Keep the app buildable on the iOS Simulator.

## Required Files or Areas

- `App/Cairn.xcodeproj`
- `App/Cairn/App/CairnApp.swift`
- `App/Cairn/App/RootView.swift`
- `App/Cairn/Resources/`
- `App/CairnTests/`
- `App/CairnUITests/`

## Key Design Decisions

- SwiftUI is the app UI framework.
- Root navigation starts in the app layer.
- Feature development is deferred until domain and persistence boundaries are established.

## Validation Requirements

- Generic iOS Simulator build succeeds.
- Unit-test target remains discoverable.
- README build instructions remain accurate.

## Review Focus

- Minimal skeleton with no business logic.
- Correct project location and target setup.
- Alignment with documented source layout.

## Commit Intent

Commit a buildable application skeleton for future feature work.
