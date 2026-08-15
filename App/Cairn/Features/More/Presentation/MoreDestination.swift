//
//  MoreDestination.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

enum MoreDestination: String, CaseIterable, Identifiable {
    case goals
    case categories
    case recurringTransactions

    var id: Self { self }

    var title: String {
        switch self {
        case .goals:
            "Goals"
        case .categories:
            "Categories"
        case .recurringTransactions:
            "Recurring Transactions"
        }
    }

    var systemImage: String {
        switch self {
        case .goals:
            "target"
        case .categories:
            "tag"
        case .recurringTransactions:
            "repeat"
        }
    }
}
