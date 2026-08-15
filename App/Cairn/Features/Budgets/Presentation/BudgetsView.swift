//
//  BudgetsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct BudgetsView: View {
    var body: some View {
        ContentUnavailableView(
            "Budgets",
            systemImage: "chart.pie",
            description: Text("Your budgets will appear here.")
        )
        .navigationTitle("Budgets")
    }
}
