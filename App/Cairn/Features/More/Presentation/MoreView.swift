//
//  MoreView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct MoreView: View {
    var body: some View {
        List {
            ForEach(MoreDestination.allCases) { destination in
                NavigationLink(value: destination) {
                    Label(destination.title, systemImage: destination.systemImage)
                }
            }
        }
        .navigationTitle("More")
        .navigationDestination(for: MoreDestination.self) { destination in
            moreDestinationView(for: destination)
        }
    }

    @ViewBuilder
    private func moreDestinationView(for destination: MoreDestination) -> some View {
        switch destination {
        case .goals:
            GoalsView()
        case .categories:
            CategoriesView()
        case .recurringTransactions:
            RecurringTransactionsView()
        }
    }
}
