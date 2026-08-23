# Milestone 51: CI / GitHub Workflow

Status: completed

## Objective

Add a minimal GitHub Actions CI workflow that verifies Cairn remains buildable and testable on pull requests and pushes to `main`.

Do not add release, deployment, signing, distribution, caching, or package-publishing automation.

## Initial Inspection

### Repository Structure

Current repository structure remains:

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

There is currently no `.github/` directory.

### Xcode Project and Scheme

The Xcode project is:

```text
App/Cairn.xcodeproj
```

`xcodebuild -list` reports:

- scheme: `Cairn`
- targets: `Cairn`, `CairnTests`, `CairnUITests`
- build configurations: `Debug`, `Release`

The workflow should build and test the `Cairn` scheme.

### README Build and Test Commands

README currently documents:

- generic iOS Simulator Debug build
- concrete available iPhone simulator selection for unit tests
- `CODE_SIGNING_ALLOWED=NO`
- `-only-testing:CairnTests` for unit tests

CI should follow the same command shape.

### Deployment Target

The project deployment target is iOS 17.0.

### Local Simulator and Runtime Assumptions

Local validation environment at audit time:

- Xcode 26.6
- Swift 6.3.3
- available iOS runtime: iOS 26.5
- available concrete iPhone simulator includes `iPhone 17`

GitHub-hosted runner image metadata shows `macos-26` is available and current macOS 26 images use Xcode 26.6 by default. CI should use the default Xcode on `macos-26` and verify it at runtime rather than relying on an old simulator model name.

### Test Target Structure

`CairnTests` contains unit and integration tests for app startup, feature stores, finance domain, persistence repositories, migration/versioning, and local seed loading.

`CairnUITests` exists but is not included in this milestone because the requested CI should focus on buildability and unit tests, and UI-test stability has not been established.

## Workflow Requirements

Create:

```text
.github/workflows/ci.yml
```

Triggers:

- `pull_request`
- `push` to `main`

Use a GitHub-hosted macOS runner:

```yaml
runs-on: macos-26
```

Use official GitHub actions only:

- `actions/checkout@v4`

Permissions:

```yaml
permissions:
  contents: read
```

Concurrency:

- one active CI run per workflow/ref
- cancel older in-progress runs when a newer commit arrives on the same branch or PR ref

Do not use repository secrets.

## CI Steps

The workflow should:

1. Check out the repository.
2. Select or verify the default Xcode.
3. Print concise environment diagnostics:
   - `xcodebuild -version`
   - `xcrun swift --version`
   - available iOS simulator runtimes
   - available simulator devices
4. Run a committed-diff whitespace check:

   ```sh
   git -c core.fsmonitor=false diff --check <range>
   ```

5. Run a generic iOS Simulator Debug build:

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

6. Select a concrete available iPhone simulator with a small transparent shell step.
7. Run `CairnTests` on that simulator:

   ```sh
   xcodebuild \
     -project App/Cairn.xcodeproj \
     -scheme Cairn \
     -configuration Debug \
     -sdk iphonesimulator \
     -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
     CODE_SIGNING_ALLOWED=NO \
     -only-testing:CairnTests \
     -resultBundlePath TestResults/CairnTests.xcresult \
     test
   ```

Do not run `CairnUITests`.

## Simulator Strategy

Do not hardcode a simulator model such as `iPhone 17`.

Use `xcrun simctl list devices available --json` and the system Python available on GitHub runners to select the first available iPhone simulator UDID. Fail clearly if none is available.

This keeps CI resilient to normal runner-image device-name changes while still testing on a concrete simulator.

## Test Result Handling

Store the `.xcresult` bundle only when tests fail.

Use:

- `actions/upload-artifact` only if needed for failure artifacts
- short retention, such as 5 days
- no DerivedData upload

Do not upload large build products.

## Caching

Do not add DerivedData, SPM, CocoaPods, Carthage, or dependency caching.

The project currently has no meaningful third-party dependency graph to cache.

## Seed Data

CI must not depend on local seed data.

Verify:

- `Local/SeedData/cairn-seed.json` is not required
- seed opt-in remains disabled by default
- workflow does not create `Local/SeedData/`
- workflow does not commit or upload seed payloads

## Migration Fixture

The committed synthetic pre-versioning SwiftData fixture remains part of the repository and should be available to migration tests through normal checkout.

Do not regenerate the fixture in CI.

## README Update

Update `README.md` with a concise CI section explaining:

- CI runs on pull requests and pushes to `main`
- CI validates whitespace, generic simulator build, and `CairnTests`
- local seed data is not required

Do not add a status badge unless the workflow name and repository path are stable and useful.

## Validation Requirements

Run locally:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator Debug build
3. full `CairnTests` target on a concrete available iPhone simulator, if practical
4. inspect `.github/workflows/ci.yml` for YAML syntax, least-privilege permissions, simple concurrency, no secrets, no untrusted scripts, and no release/deployment behavior

Do not run `/review`.

Do not stage or commit.

## Review Focus

- Workflow is minimal and understandable.
- Workflow runs on pull requests and pushes to `main`.
- Permissions are least-privilege.
- Concurrency cancels redundant runs.
- Build uses generic iOS Simulator destination.
- Tests use a concrete available iPhone simulator without fragile model hardcoding.
- Signing is disabled for CI build/test commands.
- Unit tests run; UI tests do not.
- Failure artifacts are limited to test results and retained briefly.
- No dependency caching, secrets, deployment, or release automation is introduced.

## Final Documentation Requirements

After implementation, update this file with:

- workflow triggers
- runner and Xcode choice
- build and test commands
- simulator strategy
- permissions
- concurrency policy
- artifact policy
- seed-data independence
- validation performed

Set status to `completed`.

Update `Documentation/prompts/README.md` consistently.

## Final Workflow

### Workflow Triggers

The workflow is defined at:

```text
.github/workflows/ci.yml
```

It runs on:

- `pull_request`
- `push` to `main`

### Runner and Xcode Choice

CI uses:

```yaml
runs-on: macos-26
```

This matches the current local Xcode 26 generation and uses the default Xcode provided by the macOS 26 GitHub-hosted runner image.

The workflow verifies the environment at runtime with:

- `xcode-select -p`
- `xcodebuild -version`
- `xcrun swift --version`
- available iOS simulator runtimes
- available simulator devices

Checkout uses `fetch-depth: 2` and checks out the pull request head SHA or current push SHA. The whitespace step performs narrow one-commit fetches for the PR base SHA or push `before` SHA when the comparison object is not already present locally.

### Whitespace Check

CI checks committed changes rather than the clean post-checkout working tree.

For `pull_request` events:

```sh
git fetch --no-tags --depth=1 origin "${PR_BASE_SHA}"
git -c core.fsmonitor=false diff --check "${PR_BASE_SHA}..${PR_HEAD_SHA}"
```

For `push` events with a non-zero `before` SHA:

```sh
git fetch --no-tags --depth=1 origin "${PUSH_BEFORE_SHA}"
git -c core.fsmonitor=false diff --check "${PUSH_BEFORE_SHA}..${CURRENT_SHA}"
```

For push events where the `before` SHA is unavailable or all zeroes, the workflow checks `CURRENT_SHA^..CURRENT_SHA` when a parent exists. If the pushed commit has no parent, it falls back to comparing the empty tree against `CURRENT_SHA`.

### Build Command

CI runs a generic iOS Simulator Debug build:

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

### Test Command

CI runs unit tests only:

```sh
xcodebuild \
  -project App/Cairn.xcodeproj \
  -scheme Cairn \
  -configuration Debug \
  -sdk iphonesimulator \
  -destination "platform=iOS Simulator,id=${SIMULATOR_UDID}" \
  CODE_SIGNING_ALLOWED=NO \
  -only-testing:CairnTests \
  -resultBundlePath TestResults/CairnTests.xcresult \
  test
```

`CairnUITests` are intentionally not run in this workflow.

### Simulator Strategy

The workflow does not hardcode an iPhone model name.

It queries available simulator devices as JSON and selects the first available iPhone simulator UDID. If no available iPhone simulator exists, the selector fails with a clear error.

This keeps the workflow resilient to GitHub runner image simulator model changes.

### Permissions

Workflow permissions are limited to:

```yaml
permissions:
  contents: read
```

No write, package, deployment, pull-request mutation, or secret access is configured.

### Concurrency Policy

Concurrency is configured as:

```yaml
concurrency:
  group: ${{ github.workflow }}-${{ github.ref }}
  cancel-in-progress: true
```

This keeps one active CI run per workflow/ref and cancels older in-progress runs when a newer commit arrives.

### Artifact Policy

The workflow uploads only `TestResults/CairnTests.xcresult`, only when a failure occurs.

Artifact retention is 5 days.

DerivedData and build products are not uploaded.

### Seed-Data Independence

CI does not create `Local/SeedData/` and does not require `Local/SeedData/cairn-seed.json`.

Seed loading remains disabled by default because the workflow does not pass the DEBUG seed launch argument or environment variable.

### Caching

No dependency or DerivedData caching was added because the project has no meaningful third-party dependency graph to cache.

### README Update

`README.md` now has a concise CI section explaining:

- when CI runs
- what CI validates
- that local seed data is not required

No status badge was added.

## Validation Performed

- `git -c core.fsmonitor=false diff --check`
- YAML parsed locally with Ruby's standard YAML parser
- local generic iOS Simulator Debug build with `CODE_SIGNING_ALLOWED=NO`
- dynamic simulator selection script selected a concrete available iPhone simulator UDID
- whitespace-check shell body passed `bash -n`
- whitespace-check branch logic was dry-run locally for pull request, normal push, zero-SHA push with parent, and zero-SHA root fallback paths
- full `CairnTests` target passed on the selected local iPhone simulator
- workflow inspected for least-privilege permissions, simple concurrency, official actions only, no secrets, no caching, no UI tests, and no release/deployment automation
