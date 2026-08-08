//
//  CategoryRepository.swift
//  Cairn
//
//  Created by Karim Sheikh on 08/08/2026.
//

protocol CategoryRepository: Sendable {
    func fetchCategories() async throws -> [Category]
    func fetchCategory(id: CategoryID) async throws -> Category?
    func save(_ category: Category) async throws
    func deleteCategory(id: CategoryID) async throws
}
