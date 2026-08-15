//
//  GoalsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct GoalsView: View {
    @State private var store: GoalsStore

    init(
        goalRepository: any GoalRepository,
        calculateGoalProgress: CalculateGoalProgress
    ) {
        let progressProvider: GoalProgressProvider = { goal in
            try calculateGoalProgress(goal: goal)
        }
        _store = State(wrappedValue: GoalsStore(
            goalRepository: goalRepository,
            calculateGoalProgress: progressProvider
        ))
    }

    var body: some View {
        @Bindable var store = store

        Group {
            if store.isLoading {
                ProgressView("Loading goals")
            } else if store.isEmpty {
                ContentUnavailableView(
                    "No Goals",
                    systemImage: "target",
                    description: Text("Add your first goal to track saving progress.")
                )
            } else {
                goalList
            }
        }
        .navigationTitle("Goals")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startCreateGoal()
                } label: {
                    Label("Add Goal", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let errorMessage = store.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                    .background(.bar)
                    .accessibilityLabel(errorMessage)
            }
        }
        .sheet(item: $store.editor) { editor in
            GoalEditorView(
                editor: editor,
                cancel: { store.dismissEditor() },
                save: {
                    Task {
                        await store.saveEditor()
                    }
                }
            )
        }
        .confirmationDialog(
            "Delete Goal?",
            isPresented: Binding(
                get: { store.pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelDelete()
                    }
                }
            ),
            presenting: store.pendingDeletion
        ) { goal in
            Button("Delete Goal", role: .destructive) {
                Task {
                    await store.confirmDelete(goal)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { goal in
            Text("This cannot be undone.")
        }
        .navigationDestination(item: $store.route) { route in
            switch route {
            case let .detail(goalID):
                if let goal = store.goal(id: goalID),
                   let progress = store.progress(for: goalID) {
                    GoalDetailView(
                        goal: goal,
                        progress: progress,
                        edit: { store.startEditing(goal) },
                        delete: { store.requestDelete(goal) }
                    )
                } else {
                    ContentUnavailableView(
                        "Goal Not Found",
                        systemImage: "questionmark.folder",
                        description: Text("The selected goal is no longer available.")
                    )
                }
            }
        }
        .task {
            await store.loadGoals()
        }
    }

    private var goalList: some View {
        List(store.goals, id: \.id) { goal in
            if let progress = store.progress(for: goal.id) {
                Button {
                    store.selectDetail(goalID: goal.id)
                } label: {
                    GoalRowView(goal: goal, progress: progress)
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: goal, progress: progress))
                .swipeActions {
                    Button(role: .destructive) {
                        store.requestDelete(goal)
                    } label: {
                        Label("Delete Goal", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete Goal")
                }
            }
        }
    }

    private func accessibilityLabel(for goal: Goal, progress: GoalProgress) -> String {
        var label = "\(goal.name), target \(GoalMoneyFormatter.currency(goal.targetAmount)), current \(GoalMoneyFormatter.currency(goal.currentAmount)), remaining \(GoalMoneyFormatter.currency(progress.remainingAmount)), \(progress.isCompleted ? "completed" : "in progress")"

        if let targetDate = goal.targetDate {
            label += ", target date \(GoalDateFormatter.date(targetDate))"
        }

        return label
    }
}

private struct GoalRowView: View {
    let goal: Goal
    let progress: GoalProgress

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.body)
                    Text(progress.isCompleted ? "Completed" : "In Progress")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Text(GoalMoneyFormatter.currency(goal.targetAmount))
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Current", value: GoalMoneyFormatter.currency(goal.currentAmount))
                .font(.footnote)
            LabeledContent("Remaining", value: GoalMoneyFormatter.currency(progress.remainingAmount))
                .font(.footnote)

            if let targetDate = goal.targetDate {
                Text("Target Date \(GoalDateFormatter.date(targetDate))")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .contentShape(Rectangle())
    }
}
