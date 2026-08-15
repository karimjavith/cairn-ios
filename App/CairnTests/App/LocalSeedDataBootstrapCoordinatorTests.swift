//
//  LocalSeedDataBootstrapCoordinatorTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Foundation
import Testing
@testable import Cairn

@MainActor
struct LocalSeedDataBootstrapCoordinatorTests {
    @Test func optInDisabledMakesRootAvailableWithoutSeeding() async {
        let probe = BootstrapProbe()
        let coordinator = LocalSeedDataBootstrapCoordinator(
            configuration: LocalSeedDataConfiguration(state: .disabled(.optInNotRequested)),
            load: probe.load
        )

        #expect(coordinator.state == .notRequired)
        #expect(coordinator.isRootAvailable)

        await coordinator.startIfNeeded()

        #expect(coordinator.state == .notRequired)
        #expect(coordinator.isRootAvailable)
        #expect(probe.invocationCount == 0)
    }

    @Test func optInEnabledWithholdsRootUntilSeedingSucceeds() async throws {
        let probe = BootstrapProbe()
        let coordinator = LocalSeedDataBootstrapCoordinator(
            configuration: enabledConfiguration(),
            load: probe.load
        )

        #expect(coordinator.state == .loading)
        #expect(!coordinator.isRootAvailable)

        let task = Task {
            await coordinator.startIfNeeded()
        }
        await Task.yield()

        #expect(probe.invocationCount == 1)
        #expect(coordinator.state == .loading)
        #expect(!coordinator.isRootAvailable)

        probe.succeed()
        await task.value

        #expect(coordinator.state == .ready)
        #expect(coordinator.isRootAvailable)
    }

    @Test func successfulSeedingTransitionsToReady() async {
        let probe = BootstrapProbe(result: .seeded(LocalSeedDataSummary(
            accounts: 1,
            categories: 1,
            transactions: 1,
            budgets: 1,
            goals: 1,
            recurringTransactions: 1
        )))
        let coordinator = LocalSeedDataBootstrapCoordinator(
            configuration: enabledConfiguration(),
            load: probe.load
        )

        await coordinator.startIfNeeded()

        #expect(coordinator.state == .ready)
        #expect(coordinator.isRootAvailable)
        #expect(probe.invocationCount == 1)
    }

    @Test func failureTransitionsToExplicitFailureState() async {
        let probe = BootstrapProbe(error: LocalSeedDataError.missingFile(URL(filePath: "/tmp/missing.json")))
        let coordinator = LocalSeedDataBootstrapCoordinator(
            configuration: enabledConfiguration(),
            load: probe.load
        )

        await coordinator.startIfNeeded()

        guard case let .failed(message) = coordinator.state else {
            Issue.record("Expected failed bootstrap state")
            return
        }

        #expect(message.contains("Local seed data failed"))
        #expect(message.contains("missingFile"))
        #expect(!coordinator.isRootAvailable)
        #expect(probe.invocationCount == 1)
    }

    @Test func seedLoaderIsInvokedExactlyOnceForOneStartup() async {
        let probe = BootstrapProbe(result: .seeded(LocalSeedDataSummary(
            accounts: 0,
            categories: 0,
            transactions: 0,
            budgets: 0,
            goals: 0,
            recurringTransactions: 0
        )))
        let coordinator = LocalSeedDataBootstrapCoordinator(
            configuration: enabledConfiguration(),
            load: probe.load
        )

        await coordinator.startIfNeeded()
        await coordinator.startIfNeeded()

        #expect(coordinator.state == .ready)
        #expect(probe.invocationCount == 1)
    }

    private func enabledConfiguration() -> LocalSeedDataConfiguration {
        LocalSeedDataConfiguration(state: .enabled(URL(filePath: "/tmp/seed.json")))
    }
}

@MainActor
private final class BootstrapProbe {
    private let result: LocalSeedDataLoadResult?
    private let error: (any Error)?
    private var continuation: CheckedContinuation<LocalSeedDataLoadResult, any Error>?

    private(set) var invocationCount = 0

    init(
        result: LocalSeedDataLoadResult? = nil,
        error: (any Error)? = nil
    ) {
        self.result = result
        self.error = error
    }

    func load(configuration: LocalSeedDataConfiguration) async throws -> LocalSeedDataLoadResult {
        invocationCount += 1

        if let result {
            return result
        }

        if let error {
            throw error
        }

        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
        }
    }

    func succeed() {
        continuation?.resume(returning: .seeded(LocalSeedDataSummary(
            accounts: 0,
            categories: 0,
            transactions: 0,
            budgets: 0,
            goals: 0,
            recurringTransactions: 0
        )))
        continuation = nil
    }
}
