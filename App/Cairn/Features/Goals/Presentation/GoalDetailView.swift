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

    private var presentation: CairnProgressPresentation {
        CairnProgressPresentation.goal(
            title: goal.name,
            saved: goal.currentAmount,
            target: goal.targetAmount,
            ratio: progress.progressRatio
        )
    }

    var body: some View {
        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: CairnSpacing.section) {
                    VStack(alignment: .leading, spacing: CairnSpacing.medium) {
                        Text(goal.name)
                            .font(.headline.weight(.semibold))
                            .foregroundStyle(CairnColor.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)

                        Text(GoalMoneyFormatter.currency(goal.currentAmount))
                            .font(.system(.largeTitle, design: .serif).weight(.semibold))
                            .monospacedDigit()
                            .lineLimit(2)
                            .minimumScaleFactor(0.76)
                            .foregroundStyle(CairnColor.textPrimary)

                        Text("Saved")
                            .font(.subheadline)
                            .foregroundStyle(CairnColor.textSecondary)

                        Text(presentation.valueText)
                            .font(.body.weight(.semibold))
                            .foregroundStyle(progress.isCompleted ? CairnColor.positive : CairnColor.textPrimary)

                        ProgressView(value: presentation.visibleFraction)
                            .tint(CairnColor.plum)
                            .accessibilityHidden(true)
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityLabel("\(goal.name), \(GoalMoneyFormatter.currency(goal.currentAmount)) saved, \(presentation.valueText)")

                    VStack(alignment: .leading, spacing: CairnSpacing.large) {
                        CairnSectionHeading("Goal progress")

                        detailRow("Target", value: GoalMoneyFormatter.currency(goal.targetAmount))
                        detailRow("Remaining", value: GoalMoneyFormatter.currency(progress.remainingAmount))

                        if let targetDate = goal.targetDate {
                            detailRow("Target date", value: GoalDateFormatter.date(targetDate))
                        }
                    }

                    Button("Delete \(goal.name)", role: .destructive, action: delete)
                        .accessibilityLabel("Delete \(goal.name)")
                        .frame(minHeight: 44)
                        .padding(.top, CairnSpacing.small)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, CairnSpacing.extraLarge)
                .padding(.top, CairnSpacing.large)
                .padding(.bottom, CairnSpacing.section)
            }
        }
        .navigationTitle("Goal")
        .tint(CairnColor.plum)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit", action: edit)
                    .accessibilityLabel("Edit \(goal.name)")
            }
        }
    }

    private func detailRow(_ title: String, value: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)

            Spacer(minLength: CairnSpacing.medium)

            Text(value)
                .font(.body.weight(.medium))
                .monospacedDigit()
                .foregroundStyle(CairnColor.textPrimary)
                .multilineTextAlignment(.trailing)
                .fixedSize(horizontal: false, vertical: true)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(title), \(value)")
    }
}
