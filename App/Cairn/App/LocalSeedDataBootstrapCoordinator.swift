//
//  LocalSeedDataBootstrapCoordinator.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import Observation
import SwiftUI

@MainActor
@Observable
final class LocalSeedDataBootstrapCoordinator {
    enum State: Equatable {
        case notRequired
        case loading
        case ready
        case failed(String)
    }

    private let configuration: LocalSeedDataConfiguration
    private let load: (LocalSeedDataConfiguration) async throws -> LocalSeedDataLoadResult
    private var hasStarted = false

    private(set) var state: State

    init(
        configuration: LocalSeedDataConfiguration,
        load: @escaping (LocalSeedDataConfiguration) async throws -> LocalSeedDataLoadResult
    ) {
        self.configuration = configuration
        self.load = load

        switch configuration.state {
        case .disabled:
            state = .notRequired
        case .enabled:
            state = .loading
        }
    }

    var isRootAvailable: Bool {
        switch state {
        case .notRequired, .ready:
            true
        case .loading, .failed:
            false
        }
    }

    func startIfNeeded() async {
        guard case .enabled = configuration.state else {
            state = .notRequired
            return
        }

        guard !hasStarted else { return }
        hasStarted = true
        state = .loading

        do {
            _ = try await load(configuration)
            state = .ready
        } catch {
            state = .failed(Self.message(for: error))
        }
    }

    func retry() async {
        guard case .failed = state else { return }
        hasStarted = false
        await startIfNeeded()
    }

    private static func message(for error: any Error) -> String {
        switch error {
        case let seedError as LocalSeedDataError:
            "Local seed data failed: \(seedError)"
        default:
            "Local seed data failed: \(error)"
        }
    }
}

struct LocalSeedDataBootstrapView: View {
    let coordinator: LocalSeedDataBootstrapCoordinator
    let dependencies: AppDependencies

    var body: some View {
        switch coordinator.state {
        case .notRequired, .ready:
            RootView(dependencies: dependencies)
        case .loading:
            ProgressView("Loading local seed data")
                .task {
                    await coordinator.startIfNeeded()
                }
        case let .failed(message):
            ContentUnavailableView {
                Label("Local seed data failed", systemImage: "exclamationmark.triangle")
            } description: {
                Text(message)
            } actions: {
                Button("Retry") {
                    Task {
                        await coordinator.retry()
                    }
                }
            }
        }
    }
}
