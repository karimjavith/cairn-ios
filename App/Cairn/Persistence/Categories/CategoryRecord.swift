//
//  CategoryRecord.swift
//  Cairn
//
//  Created by Codex on 08/08/2026.
//

import Foundation
import SwiftData

@Model
nonisolated final class CategoryRecord {
    @Attribute(.unique) var id: UUID
    var name: String
    var kind: String

    init(
        id: UUID,
        name: String,
        kind: String
    ) {
        self.id = id
        self.name = name
        self.kind = kind
    }
}

extension CategoryRecord {
    convenience init(category: Category) {
        self.init(
            id: category.id.rawValue,
            name: category.name,
            kind: category.kind.persistenceValue
        )
    }

    func category() throws -> Category {
        let categoryKind = try CategoryKind(persistenceValue: kind)

        return try Category(
            id: CategoryID(rawValue: id),
            name: name,
            kind: categoryKind
        )
    }
}

nonisolated enum CategoryRecordMappingError: Error, Equatable, Sendable {
    case invalidKind(String)
}

private extension CategoryKind {
    nonisolated var persistenceValue: String {
        switch self {
        case .income:
            "income"
        case .expense:
            "expense"
        }
    }

    nonisolated init(persistenceValue: String) throws(CategoryRecordMappingError) {
        switch persistenceValue {
        case "income":
            self = .income
        case "expense":
            self = .expense
        default:
            throw .invalidKind(persistenceValue)
        }
    }
}
