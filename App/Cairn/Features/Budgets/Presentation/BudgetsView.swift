//
//  BudgetsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct BudgetsView: View {
    @State private var store: BudgetsStore

    init(
        budgetRepository: any BudgetRepository,
        categoryRepository: any CategoryRepository,
        calculateBudgetProgress: CalculateBudgetProgress
    ) {
        let progressProvider: BudgetProgressProvider = { budgetID in
            try await calculateBudgetProgress(budgetID: budgetID)
        }
        _store = State(wrappedValue: BudgetsStore(
            budgetRepository: budgetRepository,
            categoryRepository: categoryRepository,
            calculateBudgetProgress: progressProvider
        ))
    }

    var body: some View {
        @Bindable var store = store

        Group {
            if store.isLoading {
                ProgressView("Loading budgets")
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Budgets Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadBudgets()
                        }
                    }
                )
            } else if store.isEmpty {
                ContentUnavailableView(
                    "No Budgets",
                    systemImage: "chart.pie",
                    description: Text("Add your first budget to track category spending.")
                )
            } else {
                budgetList
            }
        }
        .navigationTitle("Budgets")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startCreateBudget()
                } label: {
                    Label("Add Budget", systemImage: "plus")
                }
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let errorMessage = store.errorMessage, !store.hasLoadFailed {
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
            BudgetEditorView(
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
            "Delete Budget?",
            isPresented: Binding(
                get: { store.pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelDelete()
                    }
                }
            ),
            presenting: store.pendingDeletion
        ) { budget in
            Button("Delete Budget", role: .destructive) {
                Task {
                    await store.confirmDelete(budget)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { budget in
            Text("This cannot be undone.")
        }
        .navigationDestination(item: $store.route) { route in
            switch route {
            case let .detail(budgetID):
                if let budget = store.budget(id: budgetID),
                   let progress = store.progress(for: budgetID) {
                    BudgetDetailView(
                        budget: budget,
                        progress: progress,
                        categoryName: store.categoryName(for: budget.categoryID),
                        edit: { store.startEditing(budget) },
                        delete: { store.requestDelete(budget) }
                    )
                } else {
                    ContentUnavailableView(
                        "Budget Not Found",
                        systemImage: "questionmark.folder",
                        description: Text("The selected budget is no longer available.")
                    )
                }
            }
        }
        .task {
            await store.loadBudgets()
        }
    }

    private var budgetList: some View {
        List(store.budgets, id: \.id) { budget in
            if let progress = store.progress(for: budget.id) {
                Button {
                    store.selectDetail(budgetID: budget.id)
                } label: {
                    BudgetRowView(
                        budget: budget,
                        progress: progress,
                        categoryName: store.categoryName(for: budget.categoryID)
                    )
                }
                .buttonStyle(.plain)
                .accessibilityLabel(accessibilityLabel(for: budget, progress: progress))
                .swipeActions {
                    Button(role: .destructive) {
                        store.requestDelete(budget)
                    } label: {
                        Label("Delete Budget", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete Budget")
                }
            }
        }
    }

    private func accessibilityLabel(for budget: Budget, progress: BudgetProgress) -> String {
        "\(store.categoryName(for: budget.categoryID)), limit \(BudgetMoneyFormatter.currency(budget.limit)), spent \(BudgetMoneyFormatter.currency(progress.spent)), remaining \(BudgetMoneyFormatter.currency(progress.remaining)), \(BudgetDateFormatter.period(budget.period))"
    }
}

private struct BudgetRowView: View {
    let budget: Budget
    let progress: BudgetProgress
    let categoryName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(categoryName)
                        .font(.body)
                    Text(BudgetDateFormatter.period(budget.period))
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 16)

                Text(BudgetMoneyFormatter.currency(budget.limit))
                    .font(.body.monospacedDigit())
                    .multilineTextAlignment(.trailing)
            }

            LabeledContent("Spent", value: BudgetMoneyFormatter.currency(progress.spent))
                .font(.footnote)
            LabeledContent("Remaining", value: BudgetMoneyFormatter.currency(progress.remaining))
                .font(.footnote)
        }
        .contentShape(Rectangle())
    }
}
