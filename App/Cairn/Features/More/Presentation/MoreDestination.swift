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
    case creditScore

    var id: Self { self }

    var title: String {
        switch self {
        case .goals:
            "Goals"
        case .categories:
            "Categories"
        case .recurringTransactions:
            "Recurring Transactions"
        case .creditScore:
            "Credit Score"
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
        case .creditScore:
            "gauge"
        }
    }
}
