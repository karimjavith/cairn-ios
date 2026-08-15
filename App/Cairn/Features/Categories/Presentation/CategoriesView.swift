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

        Group {
            if store.isLoading {
                ProgressView("Loading categories")
            } else if store.isEmpty {
                ContentUnavailableView(
                    "No Categories",
                    systemImage: "tag",
                    description: Text("Add your first category to organize transactions and budgets.")
                )
            } else {
                categoryList
            }
        }
        .navigationTitle("Categories")
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
            Text("This cannot be undone.")
        }
        .task {
            await store.loadCategories()
        }
    }

    private var categoryList: some View {
        List(store.categories, id: \.id) { category in
            CategoryRowView(
                category: category,
                edit: { store.startEditing(category) }
            )
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
}

private struct CategoryRowView: View {
    let category: Category
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            VStack(alignment: .leading, spacing: 4) {
                Text(category.name)
                    .font(.body)
                Text(category.kind.displayName)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(category.name), \(category.kind.displayName)")
    }
}
