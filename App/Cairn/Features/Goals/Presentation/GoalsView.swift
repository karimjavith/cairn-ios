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

        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            if store.isLoading {
                ProgressView("Loading goals")
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Goals Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadGoals()
                        }
                    }
                )
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else if store.isEmpty {
                emptyGoalsView
            } else {
                goalList
            }
        }
        .navigationTitle("Goals")
        .tint(CairnColor.plum)
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
            if let errorMessage = store.errorMessage, !store.hasLoadFailed {
                Label {
                    Text(errorMessage)
                        .fixedSize(horizontal: false, vertical: true)
                } icon: {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundStyle(CairnColor.warning)
                        .accessibilityHidden(true)
                }
                .font(.subheadline)
                .foregroundStyle(CairnColor.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(CairnSpacing.large)
                .background(CairnColor.lavenderSurface)
                .accessibilityElement(children: .ignore)
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
            Button("Delete \(goal.name)", role: .destructive) {
                Task {
                    await store.confirmDelete(goal)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { goal in
            Text("This deletes \(goal.name). This cannot be undone.")
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

    private var emptyGoalsView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "No goals yet",
                message: "Set a savings target and track your progress toward it.",
                systemImage: "target",
                actionLabel: "Add goal",
                action: { store.startCreateGoal() }
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
    }

    private var goalList: some View {
        List {
            CairnSectionHeading(
                "Savings goals",
                subtitle: store.goals.count == 1 ? "1 goal" : "\(store.goals.count) goals"
            )
            .listRowInsets(EdgeInsets(
                top: CairnSpacing.large,
                leading: CairnSpacing.extraLarge,
                bottom: CairnSpacing.medium,
                trailing: CairnSpacing.extraLarge
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(CairnColor.canvas)

            ForEach(store.goals, id: \.id) { goal in
                if let progress = store.progress(for: goal.id) {
                    Button {
                        store.selectDetail(goalID: goal.id)
                    } label: {
                        GoalRowView(goal: goal, progress: progress)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(accessibilityLabel(for: goal, progress: progress))
                    .listRowInsets(EdgeInsets(
                        top: CairnSpacing.small,
                        leading: CairnSpacing.extraLarge,
                        bottom: CairnSpacing.small,
                        trailing: CairnSpacing.extraLarge
                    ))
                    .listRowBackground(CairnColor.canvas)
                    .swipeActions {
                        Button(role: .destructive) {
                            store.requestDelete(goal)
                        } label: {
                            Label("Delete Goal", systemImage: "trash")
                        }
                        .accessibilityLabel("Delete \(goal.name)")
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
    }

    private func accessibilityLabel(for goal: Goal, progress: GoalProgress) -> String {
        let presentation = CairnProgressPresentation.goal(
            title: goal.name,
            saved: goal.currentAmount,
            target: goal.targetAmount,
            ratio: progress.progressRatio
        )
        var label = "\(presentation.accessibilityLabel), \(GoalMoneyFormatter.currency(progress.remainingAmount)) remaining"

        if let targetDate = goal.targetDate {
            label += ", target date \(GoalDateFormatter.date(targetDate))"
        }

        return label
    }
}

private struct GoalRowView: View {
    let goal: Goal
    let progress: GoalProgress

    private var presentation: CairnProgressPresentation {
        CairnProgressPresentation.goal(
            title: goal.name,
            saved: goal.currentAmount,
            target: goal.targetAmount,
            ratio: progress.progressRatio
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
                Text(goal.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CairnColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Spacer(minLength: CairnSpacing.medium)

                Text(presentation.valueText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .foregroundStyle(progress.isCompleted ? CairnColor.positive : CairnColor.textPrimary)
            }

            ProgressView(value: presentation.visibleFraction)
                .tint(CairnColor.plum)
                .accessibilityHidden(true)

            Text(presentation.detailText)
                .font(.subheadline)
                .foregroundStyle(CairnColor.textSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Text("\(GoalMoneyFormatter.currency(progress.remainingAmount)) remaining")
                .font(.footnote)
                .foregroundStyle(CairnColor.textSecondary)

            if let targetDate = goal.targetDate {
                Text("Target Date \(GoalDateFormatter.date(targetDate))")
                    .font(.footnote)
                    .foregroundStyle(CairnColor.textTertiary)
            }
        }
        .frame(minHeight: 44)
        .contentShape(Rectangle())
    }
}
