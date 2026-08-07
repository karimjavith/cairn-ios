# Cairn

Cairn is a local-first personal financial operating system for iOS.

Current status: the engineering foundation is established. Feature development has not begun.

## Platform

- iOS 17+

## Core Stack

- Swift
- SwiftUI
- SwiftData
- Swift Concurrency

## Xcode Project

The Xcode project is located at:

```text
App/Cairn.xcodeproj
```

Open it with:

```sh
open App/Cairn.xcodeproj
```

## Repository Layout

```text
cairn-ios/
├── App/
│   ├── Cairn.xcodeproj
│   ├── Cairn/
│   ├── CairnTests/
│   └── CairnUITests/
├── Documentation/
├── AGENTS.md
└── README.md
```

Planned but not yet created:

- `Scripts/`
- `.github/`

## Build

Generic iOS Simulator build:

```sh
xcodebuild \
  -project App/Cairn.xcodeproj \
  -scheme Cairn \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'generic/platform=iOS Simulator' \
  CODE_SIGNING_ALLOWED=NO \
  build
```

## Unit Tests

Unit tests must run on an available concrete iPhone simulator.

List available simulators:

```sh
xcrun simctl list devices available
```

Then run unit tests with the selected simulator name:

```sh
xcodebuild \
  -project App/Cairn.xcodeproj \
  -scheme Cairn \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=<Simulator Name>' \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:CairnTests \
  test
```

## Engineering Documents

- [Engineering Standards](Documentation/ENGINEERING.md)
- [Architecture](Documentation/ARCHITECTURE.md)
- [AI Agent Instructions](AGENTS.md)

## Development Workflow

- Keep `main` buildable.
- Use short-lived branches for changes.
- Use pull requests when collaborative development begins.
- Keep changes scoped and validated before review.
