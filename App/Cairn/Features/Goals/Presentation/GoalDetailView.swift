//
//  GoalDetailView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct GoalDetailView: View {
    let goal: Goal
    let progress: GoalProgress
    let edit: () -> Void
    let delete: () -> Void

    var body: some View {
        List {
            Section("Goal") {
                LabeledContent("Name", value: goal.name)
                LabeledContent("Target", value: GoalMoneyFormatter.currency(goal.targetAmount))
                LabeledContent("Current", value: GoalMoneyFormatter.currency(goal.currentAmount))
                if let targetDate = goal.targetDate {
                    LabeledContent("Target Date", value: GoalDateFormatter.date(targetDate))
                }
            }

            Section("Progress") {
                LabeledContent("Remaining", value: GoalMoneyFormatter.currency(progress.remainingAmount))
                LabeledContent("Status", value: progress.isCompleted ? "Completed" : "In Progress")
                LabeledContent("Progress", value: GoalMoneyFormatter.ratio(progress.progressRatio))
            }

            Section {
                Button("Delete Goal", role: .destructive, action: delete)
                    .accessibilityLabel("Delete Goal")
            }
        }
        .navigationTitle("Goal")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
            }
        }
    }
}
