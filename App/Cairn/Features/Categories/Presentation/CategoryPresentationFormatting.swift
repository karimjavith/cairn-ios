//
//  CategoryPresentationFormatting.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

extension CategoryKind: CaseIterable {
    static var allCases: [CategoryKind] {
        [
            .expense,
            .income
        ]
    }

    var displayName: String {
        switch self {
        case .income:
            "Income"
        case .expense:
            "Expense"
        }
    }
}
