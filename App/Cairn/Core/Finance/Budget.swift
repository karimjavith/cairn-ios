//
//  Budget.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import Foundation

nonisolated struct BudgetID: Equatable, Hashable, Codable, Sendable {
    let rawValue: UUID

    init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }
}

nonisolated struct BudgetPeriod: Equatable, Hashable, Sendable {
    let startDate: Date
    let endDate: Date

    init(startDate: Date, endDate: Date) throws {
        guard endDate > startDate else {
            throw ValidationError.invalidDateRange
        }

        self.startDate = startDate
        self.endDate = endDate
    }
}

extension BudgetPeriod {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case invalidDateRange
    }
}

nonisolated extension BudgetPeriod: Codable {
    private enum CodingKeys: String, CodingKey {
        case startDate
        case endDate
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        try self.init(
            startDate: container.decode(Date.self, forKey: .startDate),
            endDate: container.decode(Date.self, forKey: .endDate)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
    }
}

nonisolated struct Budget: Equatable, Hashable, Sendable {
    let id: BudgetID
    let categoryID: CategoryID
    let limit: Money
    let period: BudgetPeriod

    init(
        id: BudgetID = BudgetID(),
        categoryID: CategoryID,
        limit: Money,
        period: BudgetPeriod
    ) throws {
        guard limit.amount >= 0 else {
            throw ValidationError.negativeLimit
        }

        self.id = id
        self.categoryID = categoryID
        self.limit = limit
        self.period = period
    }
}

extension Budget {
    nonisolated enum ValidationError: Error, Equatable, Sendable {
        case negativeLimit
    }
}

nonisolated extension Budget: Codable {
    private enum CodingKeys: String, CodingKey {
        case id
        case categoryID
        case limit
        case currencyCode
        case period
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let limit = try Money(
            amount: container.decode(Decimal.self, forKey: .limit),
            currencyCode: container.decode(String.self, forKey: .currencyCode)
        )

        try self.init(
            id: container.decode(BudgetID.self, forKey: .id),
            categoryID: container.decode(CategoryID.self, forKey: .categoryID),
            limit: limit,
            period: container.decode(BudgetPeriod.self, forKey: .period)
        )
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)

        try container.encode(id, forKey: .id)
        try container.encode(categoryID, forKey: .categoryID)
        try container.encode(limit.amount, forKey: .limit)
        try container.encode(limit.currencyCode, forKey: .currencyCode)
        try container.encode(period, forKey: .period)
    }
}
