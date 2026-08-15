//
//  AppTab.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

enum AppTab: String, CaseIterable, Identifiable {
    case dashboard
    case accounts
    case transactions
    case budgets
    case more

    var id: Self { self }

    var title: String {
        switch self {
        case .dashboard:
            "Dashboard"
        case .accounts:
            "Accounts"
        case .transactions:
            "Transactions"
        case .budgets:
            "Budgets"
        case .more:
            "More"
        }
    }

    var systemImage: String {
        switch self {
        case .dashboard:
            "gauge"
        case .accounts:
            "creditcard"
        case .transactions:
            "list.bullet.rectangle"
        case .budgets:
            "chart.pie"
        case .more:
            "ellipsis"
        }
    }
}
