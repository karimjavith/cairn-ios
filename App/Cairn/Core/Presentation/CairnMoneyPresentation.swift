//
//  CairnMoneyPresentation.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import Foundation
import SwiftUI

enum CairnMoneyPresentation {
    nonisolated static func currency(_ money: Money) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = money.currencyCode

        return formatter.string(from: money.amount as NSDecimalNumber)
            ?? "\(money.amount) \(money.currencyCode)"
    }

    nonisolated static func absoluteCurrency(_ money: Money) -> String {
        currency(money.amount < 0 ? -money : money)
    }
}

struct CairnHeroAmountStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.largeTitle.weight(.semibold))
            .monospacedDigit()
            .lineLimit(2)
            .minimumScaleFactor(0.82)
            .accessibilityAddTraits(.isStaticText)
    }
}

struct CairnRowAmountStyle: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.headline.weight(.semibold))
            .monospacedDigit()
            .multilineTextAlignment(.trailing)
            .lineLimit(2)
            .minimumScaleFactor(0.86)
    }
}

extension View {
    func cairnHeroAmount() -> some View {
        modifier(CairnHeroAmountStyle())
    }

    func cairnRowAmount() -> some View {
        modifier(CairnRowAmountStyle())
    }
}
