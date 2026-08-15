//
//  BudgetDetailView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct BudgetDetailView: View {
    let budget: Budget
    let progress: BudgetProgress
    let categoryName: String
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        List {
            Section("Budget") {
                LabeledContent("Category", value: categoryName)
                LabeledContent("Limit", value: BudgetMoneyFormatter.currency(budget.limit))
                LabeledContent("Period", value: BudgetDateFormatter.period(budget.period))
            }

            Section("Progress") {
                LabeledContent("Spent", value: BudgetMoneyFormatter.currency(progress.spent))
                LabeledContent("Remaining", value: BudgetMoneyFormatter.currency(progress.remaining))
            }

            Section {
                Button("Delete Budget", role: .destructive, action: delete)
                    .accessibilityLabel("Delete Budget")
            }
        }
        .navigationTitle("Budget")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
            }
        }
    }
}
