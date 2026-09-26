//
//  CategoriesView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct CategoriesView: View {
    @State private var store: CategoriesStore

    init(
        categoryRepository: any CategoryRepository,
        transactionRepository: any TransactionRepository,
        budgetRepository: any BudgetRepository
    ) {
        _store = State(wrappedValue: CategoriesStore(
            categoryRepository: categoryRepository,
            transactionRepository: transactionRepository,
            budgetRepository: budgetRepository
        ))
    }

    var body: some View {
        @Bindable var store = store

        ZStack {
            CairnColor.canvas
                .ignoresSafeArea()

            if store.isLoading {
                ProgressView("Loading categories")
                    .tint(CairnColor.plum)
                    .foregroundStyle(CairnColor.textSecondary)
            } else if store.hasLoadFailed, let errorMessage = store.errorMessage {
                LoadFailureView(
                    title: "Categories Unavailable",
                    message: errorMessage,
                    retry: {
                        Task {
                            await store.loadCategories()
                        }
                    }
                )
                .padding(.horizontal, CairnSpacing.extraLarge)
            } else if store.isEmpty {
                emptyCategoriesView
            } else {
                categoryList
            }
        }
        .navigationTitle("Categories")
        .tint(CairnColor.plum)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    store.startCreateCategory()
                } label: {
                    Label("Add Category", systemImage: "plus")
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
            CategoryEditorView(
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
            "Delete Category?",
            isPresented: Binding(
                get: { store.pendingDeletion != nil },
                set: { isPresented in
                    if !isPresented {
                        store.cancelDelete()
                    }
                }
            ),
            presenting: store.pendingDeletion
        ) { category in
            Button("Delete \(category.name)", role: .destructive) {
                Task {
                    await store.confirmDelete(category)
                }
            }
            Button("Cancel", role: .cancel) {
                store.cancelDelete()
            }
        } message: { category in
            Text("This deletes \(category.name). This cannot be undone.")
        }
        .task {
            await store.loadCategories()
        }
    }

    private var emptyCategoriesView: some View {
        ScrollView {
            CairnEmptyStateView(
                title: "No categories yet",
                message: "Add a category to organize transactions and budgets.",
                systemImage: "tag",
                actionLabel: "Add category",
                action: { store.startCreateCategory() }
            )
            .padding(.horizontal, CairnSpacing.extraLarge)
            .padding(.top, CairnSpacing.section)
        }
    }

    private var categoryList: some View {
        List {
            CairnSectionHeading(
                "Your categories",
                subtitle: store.categories.count == 1 ? "1 category" : "\(store.categories.count) categories"
            )
                .listRowInsets(EdgeInsets(
                    top: CairnSpacing.large,
                    leading: CairnSpacing.extraLarge,
                    bottom: CairnSpacing.medium,
                    trailing: CairnSpacing.extraLarge
                ))
                .listRowSeparator(.hidden)
                .listRowBackground(CairnColor.canvas)

            ForEach(store.categories, id: \.id) { category in
                CategoryRowView(
                    category: category,
                    edit: { store.startEditing(category) }
                )
                .listRowInsets(EdgeInsets(
                    top: CairnSpacing.small,
                    leading: CairnSpacing.extraLarge,
                    bottom: CairnSpacing.small,
                    trailing: CairnSpacing.extraLarge
                ))
                .listRowBackground(CairnColor.canvas)
                .swipeActions {
                    Button(role: .destructive) {
                        store.requestDelete(category)
                    } label: {
                        Label("Delete \(category.name)", systemImage: "trash")
                    }
                    .accessibilityLabel("Delete \(category.name)")
                }
            }
        }
        .scrollContentBackground(.hidden)
    }
}

private struct CategoryRowView: View {
    let category: Category
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
                Text(category.name)
                    .font(.body.weight(.medium))
                    .foregroundStyle(CairnColor.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
                Text(category.kind.displayName)
                    .font(.subheadline)
                    .foregroundStyle(category.kind == .income ? CairnColor.positive : CairnColor.negative)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(minHeight: 44)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name), \(category.kind.displayName)")
    }
}
