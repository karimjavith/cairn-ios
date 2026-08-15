//
//  TransactionsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct TransactionsView: View {
    var body: some View {
        ContentUnavailableView(
            "Transactions",
            systemImage: "list.bullet.rectangle",
            description: Text("Your transactions will appear here.")
        )
        .navigationTitle("Transactions")
    }
}
