//
//  Category.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation

nonisolated struct CategoryID: Equatable, Hashable, Codable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

nonisolated enum CategoryKind: Equatable, Hashable, Codable, Sendable {
    case income
    case expense
}

nonisolated struct Category: Equatable, Hashable, Sendable {
    let id: CategoryID
    let name: String
    let kind: CategoryKind

    init(
        id: CategoryID = CategoryID(),
        name: String,
        kind: CategoryKind
    ) throws {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedName.isEmpty else {
            throw ValidationError.emptyName
        }

        self.id = id
        self.name = trimmedName
        self.kind = kind
    }
}

extension Category {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case emptyName
    }
}

nonisolated extension Category: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case name
        case kind
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            id: container.decode(CategoryID.self, forKey: .id),
            name: container.decode(String.self, forKey: .name),
            kind: container.decode(CategoryKind.self, forKey: .kind)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(kind, forKey: .kind)
    }
}
