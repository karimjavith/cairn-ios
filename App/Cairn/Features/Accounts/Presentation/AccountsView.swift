//
//  AccountsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct AccountsView: View {
    var body: some View {
        ContentUnavailableView(
            "Accounts",
            systemImage: "creditcard",
            description: Text("Your accounts will appear here.")
        )
        .navigationTitle("Accounts")
    }
}
