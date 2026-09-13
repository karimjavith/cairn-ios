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

        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            if store.isLoading {
                ProgressView("Loading budgets")
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                VStack {
                    LoadFailureView(
                        title: "Budgets Unavailable",
                        message: errorMessage,
                        retry: {
                            Task {
                                await store.loadBudgets()
                            }
                        }
                    )
                }
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else if store.isEmpty {
                emptyBudgetsView
            } else {
                budgetList
            }
        }
        .navigationTitle("Budgets")
        .tint(CairnColor.plum)
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
            Button("Delete \(store.categoryName(for: budget.categoryID)) Budget", role: .destructive) {
                Task {
                    await store.confirmDelete(budget)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { budget in
            Text("This deletes the \(store.categoryName(for: budget.categoryID)) budget. This cannot be undone.")
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

    private var emptyBudgetsView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "No budgets yet",
                message: "Create a budget to set a spending boundary for a category.",
                systemImage: "chart.pie",
                actionLabel: "Add budget",
                action: { store.startCreateBudget() }
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
        .scrollContentBackground(.hidden)
    }

    private var budgetList: some View {
        List {
            CairnSectionHeading(
                "Budget status",
                subtitle: budgetCountText(store.budgets.count)
            )
            .listRowInsets(EdgeInsets(
                top: CairnSpacing.large,
                leading: CairnSpacing.extraLarge,
                bottom: CairnSpacing.medium,
                trailing: CairnSpacing.extraLarge
            ))
            .listRowSeparator(.hidden)
            .listRowBackground(CairnColor.canvas)

            ForEach(store.budgets, id: \.id) { budget in
                if let progress = store.progress(for: budget.id) {
                    Button {
                        store.selectDetail(budgetID: budget.id)
                    } label: {
                        BudgetRowView(
                            presentation: BudgetProgressPresentation.make(
                                categoryName: store.categoryName(for: budget.categoryID),
                                progress: progress
                            ),
                            periodText: BudgetDateFormatter.period(budget.period),
                            showsSeparator: budget.id != store.budgets.last?.id
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
                        .accessibilityLabel("Delete \(store.categoryName(for: budget.categoryID)) Budget")
                    }
                    .listRowInsets(EdgeInsets(
                        top: 0,
                        leading: CairnSpacing.extraLarge,
                        bottom: 0,
                        trailing: CairnSpacing.extraLarge
                    ))
                    .listRowSeparator(.hidden)
                    .listRowBackground(CairnColor.canvas)
                }
            }

            Color.clear
                .frame(height: CairnSpacing.section)
                .listRowInsets(.init())
                .listRowSeparator(.hidden)
                .listRowBackground(CairnColor.canvas)
        }
        .listStyle(.plain)
        .listRowSpacing(0)
        .environment(\.defaultMinListRowHeight, 0)
        .scrollContentBackground(.hidden)
        .background(CairnColor.canvas)
    }

    private func accessibilityLabel(for budget: Budget, progress: BudgetProgress) -> String {
        BudgetProgressPresentation.make(
            categoryName: store.categoryName(for: budget.categoryID),
            progress: progress
        )
        .accessibilityLabel
    }

    private func budgetCountText(_ count: Int) -> String {
        count == 1 ? "1 budget" : "\(count) budgets"
    }
}

private struct BudgetRowView: View {
    let presentation: BudgetProgressPresentation
    let periodText: String
    let showsSeparator: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.small) {
            HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
                Text(presentation.categoryName)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CairnColor.textPrimary)
                    .lineLimit(2)

                Spacer(minLength: CairnSpacing.medium)

                Text(presentation.valueText)
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
                    .minimumScaleFactor(0.86)
                    .foregroundStyle(presentation.valueColor)
            }

            ProgressView(value: presentation.visibleFraction)
                .tint(presentation.progressColor)
                .accessibilityHidden(true)

            HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
                Text(presentation.detailText)
                    .font(.caption)
                    .foregroundStyle(CairnColor.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: CairnSpacing.medium)

                Text(periodText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(CairnColor.textSecondary)
                    .multilineTextAlignment(.trailing)
                    .lineLimit(2)
            }

            if let stateText = presentation.visibleStateText {
                Text(stateText)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(presentation.valueColor)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.vertical, CairnSpacing.medium)
        .contentShape(Rectangle())
        .overlay(alignment: .bottom) {
            if showsSeparator {
                Rectangle()
                    .fill(CairnColor.separator)
                    .frame(height: 1)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(presentation.accessibilityLabel)
    }
}

private extension BudgetProgressPresentation {
    var visibleStateText: String? {
        switch status {
        case .normal:
            nil
        case .nearLimit:
            "Near limit"
        case .fullySpent:
            "Fully spent"
        case .overspent:
            "Overspent"
        }
    }

    var valueColor: Color {
        switch status {
        case .fullySpent:
            CairnColor.warning
        case .overspent:
            CairnColor.negative
        case .normal, .nearLimit:
            CairnColor.textPrimary
        }
    }

    var progressColor: Color {
        switch status {
        case .overspent:
            CairnColor.negative
        case .nearLimit, .fullySpent:
            CairnColor.warning
        case .normal:
            CairnColor.plum
        }
    }
}
