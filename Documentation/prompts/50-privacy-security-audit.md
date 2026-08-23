# Milestone 50: Privacy / Security Audit

Status: completed

## Objective

Audit Cairn for concrete privacy and security risks involving local financial data, persistence, logging, development tooling, error presentation, and application configuration.

Do not add speculative security infrastructure. Production changes should be made only when the audit identifies a real risk with concrete privacy, security, or data-integrity impact.

## Audit Scope

Inspect:

- app startup and dependency composition
- SwiftData container setup and repositories
- local seed-data loading and bootstrap
- persistence migration and startup failure behavior
- error recovery UX
- feature stores, editors, detail views, and load states
- development and test fixtures
- project configuration, entitlements, permissions, and build settings
- repository-tracked files and ignore rules
- external dependencies, networking, clipboard, sharing, and analytics surfaces

## Constraints

- Audit before modifying production code.
- Fix only real privacy or security risks.
- Do not introduce networking, analytics, crash reporting, cloud sync, export, sharing, or encryption infrastructure in this milestone.
- Do not change domain semantics.
- Do not change persistence ownership or create secondary stores.
- Do not silently reset, delete, overwrite, or recreate user data.
- Do not weaken DEBUG-only seed-data controls.
- Do not commit seed payloads, secrets, local databases, derived data, environment files, or user-specific Xcode state.
- Do not add production logging noise.
- Do not run `/review`.
- Do not stage or commit.

## Audit Method

Produce findings categorized as:

- sensitive-data exposure
- unsafe logging/debugging
- local-storage risk
- seed/development tooling risk
- destructive recovery risk
- error-information leakage
- configuration/build risk
- dependency/supply-chain concern
- meaningful test gap
- acceptable current limitation

When a current limitation is acceptable because of platform behavior or explicit product scope, document the assumption precisely without claiming guarantees not established by code.

## Data-Handling Review

Search the repository for logging, diagnostics, and debug output, including:

- `print`
- `debugPrint`
- `NSLog`
- `OSLog`
- `Logger`
- assertions and fatal diagnostics
- raw error descriptions
- test and debug helpers

Verify sensitive financial information cannot leak through:

- balances
- transaction amounts
- transaction memos
- account names
- goal and budget financial values
- seed payload contents
- temporary files or generated artifacts
- screenshots or previews
- URL query parameters

If logging is genuinely needed, it must remain minimal and metadata-only.

## Local Persistence Review

Verify:

- SwiftData store configuration is app-owned.
- No store file is deliberately placed in a shared or public container.
- No secondary persistence copy, export file, cache, or temp copy of user financial data is created.
- Startup and migration failures remain non-destructive.
- The app does not silently reset, delete, or recreate stores on failure.

Document platform-provided local-storage assumptions carefully. Do not claim encryption-at-rest guarantees, regulatory compliance, penetration testing, or security certification unless established by implementation and validation.

## Seed-Data Review

Verify:

- `Local/SeedData/` remains ignored.
- No actual seed payload is tracked.
- Seed loading is DEBUG-only.
- Explicit opt-in is still required.
- Release builds cannot activate developer seed functionality.
- Seed data is not copied into the app bundle for Release.
- Seed bootstrap does not print seed contents.
- Seed failures do not expose full payload details.

Do not weaken the local-only seed requirement.

## Build-Configuration Review

Audit Debug and Release behavior.

Verify:

- Developer seed functionality cannot activate in Release.
- Debug-only developer diagnostics are compiled out where intended.
- Test fixtures and development flags do not affect production startup.
- App configuration does not request unused privacy-sensitive platform capabilities.

Do not change signing, team, or bundle configuration unless a real issue is found.

## Error-UX Review

User-facing errors must not expose:

- SwiftData internals
- file-system paths
- database URLs
- internal model or type names
- raw underlying error dumps

Developer-only diagnostics may retain useful technical detail in DEBUG when they do not include sensitive financial values or seed payload contents.

## Privacy-Surface Review

Search for:

- `URLSession`
- Network framework usage
- third-party SDKs
- analytics or crash-reporting clients
- remote API URLs
- contacts, photos, camera, location, notifications, tracking, or background modes
- clipboard, share, export, or open-URL behavior

If none exist, document that current financial data flows are local-only.

Do not introduce any new external data surface in this milestone.

## Dependency Review

Inspect external package and dependency state.

Verify:

- no unnecessary third-party runtime dependency handles financial data
- no unexpected package has been introduced
- repository fixtures contain only synthetic data

Do not perform an internet-wide vulnerability audit unless there is an actual external dependency to inspect.

## Git-Safety Review

Check for potentially sensitive tracked files:

- seed payloads
- local SwiftData stores or databases, except documented synthetic test fixtures
- `xcuserdata`
- DerivedData
- environment files
- API keys, tokens, credentials, certificates, or provisioning profiles
- local configuration files

If a suspicious file is found, report the path safely without printing secret contents.

## Security-Boundary Review

Verify:

- no service locator or global mutable repository state has appeared
- persistence remains app-owned
- user data cannot be silently overwritten by seed or migration behavior
- destructive deletes retain existing confirmations or integrity checks

Keep privacy and security behavior in the appropriate app, persistence, or presentation boundary. Do not add security terminology to domain logic without a behavioral need.

## Testing Plan

Add focused regression tests only for actual fixes.

Prioritize:

- Release configuration cannot enable seed bootstrap
- sanitized presentation errors do not expose raw internals
- ignored local seed paths remain untracked
- developer diagnostics do not include seed payload contents

Do not create a broad security-test framework.

## Validation Requirements

Run:

1. `git -c core.fsmonitor=false diff --check`
2. generic iOS Simulator Debug build
3. generic iOS Simulator Release build
4. focused tests for changed areas
5. verify local seed path remains ignored and untracked
6. repository search for obvious credential, secret, and local-database artifacts

Do not run the full `CairnTests` suite unless necessary.

## Review Focus

- No sensitive financial values are logged or exposed through diagnostics.
- User-facing errors remain sanitized and actionable.
- Seed data remains local, DEBUG-only, opt-in, ignored, and untracked.
- Persistence failure handling is non-destructive.
- Release builds do not activate development tooling.
- The app does not request unnecessary platform capabilities.
- No new external data surface, network client, analytics client, or third-party dependency is introduced.

## Final Documentation Requirements

After implementation, update this file with an `Audit Findings` section covering:

- risks found
- fixes made
- verified protections
- accepted limitations
- deferred security work, if any

Set status to `completed`.

Update `Documentation/prompts/README.md` consistently.

## Initial Audit Findings

### Sensitive-Data Exposure

- No production logging, analytics, networking, sharing, clipboard, export, screenshot, or preview path was found that deliberately emits account names, balances, transaction amounts, memos, budget values, goal values, or seed payload contents.
- Test fixtures contain synthetic finance values. The tracked pre-versioning SwiftData fixture is documented by Milestone 46 as synthetic migration compatibility data.

### Unsafe Logging/Debugging

- Repository search found no `print`, `debugPrint`, `NSLog`, `OSLog`, `Logger`, `fatalError`, `assertionFailure`, or production raw-error logging in app source.
- `CairnApp.startupFailureMessage(for:)` deliberately ignores the underlying `ModelContainer` error and returns a sanitized non-destructive message.

### Local-Storage Risk

- The production `ModelContainer` is created once by `CairnApp` using the app-owned SwiftData default location with `isStoredInMemoryOnly: false`.
- No app source deliberately places the SwiftData store in a shared container, public directory, or secondary export/cache/temp location.
- Current code relies on platform-managed app-container storage. This audit does not establish a custom encryption-at-rest guarantee.

### Seed/Development Tooling Risk

- `Local/SeedData/` remains ignored, and no seed payload is tracked.
- Seed loading remains DEBUG-only in app composition and requires explicit opt-in through the documented launch argument or environment variable.
- Release configuration resolution returns `.releaseBuild` and does not read or seed data even if opt-in flags are present.
- Concrete issue found: the DEBUG seed bootstrap failure message interpolates raw `LocalSeedDataError`. For `.missingFile(URL)`, Swift's enum rendering can expose the local seed file path in UI. This is developer-only, but it is still unnecessary information disclosure and should be sanitized.

### Destructive Recovery Risk

- Startup persistence failure shows a non-destructive failure screen and does not reset, delete, or recreate the store.
- Seed loading refuses non-empty stores and does not merge into or wipe user data.
- Migration infrastructure has no destructive fallback stage.

### Error-Information Leakage

- Feature load, save, delete, and validation errors use feature-owned user-facing strings rather than raw repository or SwiftData errors.
- The only raw error presentation found is the DEBUG seed bootstrap message described above.

### Configuration/Build Risk

- Generated app Info.plist settings do not include usage-description keys for contacts, photos, camera, location, notifications, tracking, or background modes.
- No entitlements file or background mode configuration was found.
- The Xcode project has empty package product dependencies for app and test targets.
- Local Xcode user state exists on disk under ignored `xcuserdata` paths but is not tracked.

### Dependency/Supply-Chain Concern

- No Swift Package, CocoaPods, Carthage, analytics, crash-reporting, or third-party runtime dependency is configured.

### Meaningful Test Gap

- Existing tests cover Release seed configuration skip behavior and non-destructive startup failure text.
- A focused regression test should cover sanitized DEBUG seed bootstrap messages so paths and raw error dumps are not exposed.

### Acceptable Current Limitation

- Cairn currently relies on the platform app sandbox and SwiftData default local storage behavior. No custom data-protection or encryption-at-rest layer is implemented in this milestone.
- The pre-versioning SwiftData fixture remains tracked because it is synthetic and required for migration compatibility testing.

## Audit Findings

### Risks Found

- DEBUG local seed bootstrap failures interpolated raw error values into UI. For `LocalSeedDataError.missingFile(URL)`, that could expose the local seed file path. For unexpected errors, raw string interpolation could also expose implementation details.

### Fixes Made

- Sanitized `LocalSeedDataBootstrapCoordinator` failure messages:
  - known `LocalSeedDataError` values now map to concise metadata-only messages
  - unknown errors now use a generic local seed failure message
  - missing-file failures no longer expose the filesystem path
- Added focused regression coverage for sanitized seed bootstrap failures, including protection against raw enum case text, local paths, and unexpected raw error descriptions.

### Verified Protections

- App source contains no production logging API usage for sensitive financial data.
- Feature and startup errors remain plain-language and do not expose SwiftData internals, database URLs, file paths, or raw underlying errors.
- The production SwiftData container remains app-owned and uses the platform-managed app container. No shared/public store path, secondary export copy, cache, or temp copy of user data was introduced.
- Startup persistence failure remains non-destructive and does not reset, delete, or recreate the local store.
- Migration infrastructure remains versioned and non-destructive.
- Seed loading remains DEBUG-only, explicit opt-in, and refuses non-empty stores.
- `Local/SeedData/` remains ignored, and no seed payload is tracked.
- Release seed configuration remains unable to seed, even when opt-in flags are present.
- No network client, analytics client, crash-reporting client, remote API, clipboard/share/export flow, permission usage-description key, entitlement, background mode, or third-party runtime dependency was found.
- Tracked database-like files are limited to the documented synthetic pre-versioning SwiftData fixture used for migration compatibility testing.

### Accepted Limitations

- Cairn relies on the iOS app sandbox and SwiftData default local persistence behavior. This milestone does not establish a custom encryption-at-rest layer or make claims about regulatory compliance, penetration testing, or security certification.
- The synthetic SwiftData fixture remains tracked because it is required to verify migration compatibility from the pre-versioning store format.
- Local ignored Xcode user-state files may exist on a developer machine, but they are not tracked by Git.

### Deferred Security Work

- No deferred production security fix is required from this audit.
- Future milestones that add sync, import/export, backup, analytics, crash reporting, sharing, notifications, or third-party dependencies should perform a fresh privacy and security review before implementation.
