//
//  CairnAppStartupTests.swift
//  CairnTests
//
//  Created by Codex on 17/08/2026.
//

import Testing
@testable import Cairn

struct CairnAppStartupTests {
    @Test func startupPersistenceFailureMessageIsNonDestructive() {
        let message = CairnApp.startupFailureMessage(for: StartupFailure())

        #expect(message.contains("could not open"))
        #expect(message.contains("not reset or deleted"))
    }
}

private struct StartupFailure: Error {}
