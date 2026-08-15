//
//  AppNavigationShellTests.swift
//  CairnTests
//
//  Created by Codex on 15/08/2026.
//

import Testing
@testable import Cairn

struct AppNavigationShellTests {
    @Test func primaryDestinationsAreDeterministic() {
        #expect(AppTab.allCases.map(\.title) == [
            "Dashboard",
            "Accounts",
            "Transactions",
            "Budgets",
            "More"
        ])
    }

    @Test func moreDestinationsAreDeterministic() {
        #expect(MoreDestination.allCases.map(\.title) == [
            "Goals",
            "Categories",
            "Recurring Transactions"
        ])
    }

    @Test func rootShellCanBeConstructed() {
        _ = RootView()
    }
}
