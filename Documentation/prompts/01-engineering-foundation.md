# 01 Engineering Foundation

Status: completed

## Objective

Establish Cairn's baseline engineering standards, repository expectations, and AI-agent operating rules for a production-quality local-first iOS app.

## Scope

- Define the project purpose, platform target, and core stack.
- Document engineering principles for correctness, privacy, accessibility, testability, and maintainability.
- Establish repository workflow expectations for build, test, review, and commit hygiene.

## Constraints

- Keep guidance pragmatic and durable.
- Do not introduce speculative infrastructure.
- Do not weaken privacy-first or local-first expectations.

## Required Files or Areas

- `AGENTS.md`
- `Documentation/ENGINEERING.md`
- `README.md`
- Repository layout under `App/` and `Documentation/`

## Key Design Decisions

- Cairn targets iOS 17+ with Swift, SwiftUI, SwiftData, and Swift Concurrency.
- Engineering standards are explicit and apply to AI agents and humans.
- Validation expectations include build/test checks and clean diffs.

## Validation Requirements

- Documentation must be internally consistent.
- README must identify the Xcode project location and validation commands.
- No production code behavior should change.

## Review Focus

- Clarity of engineering principles.
- Consistency with local-first and privacy-first goals.
- Avoidance of corporate or vague process language.

## Commit Intent

Commit documentation that establishes the engineering foundation and repository workflow.
