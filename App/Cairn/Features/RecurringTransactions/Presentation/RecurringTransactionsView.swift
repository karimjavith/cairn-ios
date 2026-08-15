//
//  RecurringTransactionsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct RecurringTransactionsView: View {
    var body: some View {
        ContentUnavailableView(
            "Recurring Transactions",
            systemImage: "repeat",
            description: Text("Your recurring transactions will appear here.")
        )
        .navigationTitle("Recurring Transactions")
    }
}
