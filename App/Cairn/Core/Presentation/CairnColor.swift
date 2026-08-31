//
//  CairnColor.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import SwiftUI

enum CairnColor {
    static let canvas = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.09, green: 0.07, blue: 0.09, alpha: 1)
            : UIColor(red: 0.99, green: 0.97, blue: 0.94, alpha: 1)
    })

    static let textPrimary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.96, green: 0.93, blue: 0.91, alpha: 1)
            : UIColor(red: 0.13, green: 0.10, blue: 0.12, alpha: 1)
    })

    static let textSecondary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.72, green: 0.67, blue: 0.72, alpha: 1)
            : UIColor(red: 0.43, green: 0.38, blue: 0.43, alpha: 1)
    })

    static let textTertiary = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.52, green: 0.47, blue: 0.52, alpha: 1)
            : UIColor(red: 0.60, green: 0.55, blue: 0.60, alpha: 1)
    })

    static let plum = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.78, green: 0.58, blue: 0.76, alpha: 1)
            : UIColor(red: 0.27, green: 0.08, blue: 0.23, alpha: 1)
    })

    static let lavenderSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.17, green: 0.12, blue: 0.17, alpha: 1)
            : UIColor(red: 0.95, green: 0.91, blue: 0.96, alpha: 1)
    })

    static let lavenderStone = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.31, green: 0.24, blue: 0.32, alpha: 1)
            : UIColor(red: 0.79, green: 0.71, blue: 0.78, alpha: 1)
    })

    static let lavenderStoneDeep = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.43, green: 0.31, blue: 0.43, alpha: 1)
            : UIColor(red: 0.67, green: 0.56, blue: 0.66, alpha: 1)
    })

    static let elevatedSurface = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.14, green: 0.11, blue: 0.14, alpha: 1)
            : UIColor(red: 1.00, green: 0.98, blue: 0.96, alpha: 1)
    })

    static let separator = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.28, green: 0.23, blue: 0.28, alpha: 1)
            : UIColor(red: 0.84, green: 0.78, blue: 0.84, alpha: 1)
    })

    static let positive = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.45, green: 0.82, blue: 0.57, alpha: 1)
            : UIColor(red: 0.00, green: 0.45, blue: 0.22, alpha: 1)
    })

    static let negative = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.93, green: 0.48, blue: 0.50, alpha: 1)
            : UIColor(red: 0.72, green: 0.12, blue: 0.16, alpha: 1)
    })

    static let warning = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.94, green: 0.70, blue: 0.38, alpha: 1)
            : UIColor(red: 0.73, green: 0.43, blue: 0.05, alpha: 1)
    })

    static let neutral = textSecondary

    static let primaryButtonText = Color(uiColor: UIColor { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 0.10, green: 0.07, blue: 0.10, alpha: 1)
            : UIColor.white
    })
}

struct CairnPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(CairnColor.primaryButtonText)
            .padding(.horizontal, CairnSpacing.large)
            .padding(.vertical, CairnSpacing.medium)
            .frame(minHeight: 54)
            .background(CairnColor.plum.opacity(configuration.isPressed ? 0.82 : 1))
            .clipShape(Capsule())
    }
}

struct CairnSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.body.weight(.semibold))
            .foregroundStyle(CairnColor.plum)
            .padding(.horizontal, CairnSpacing.large)
            .padding(.vertical, CairnSpacing.medium)
            .frame(minHeight: 44)
            .background(CairnColor.lavenderSurface.opacity(configuration.isPressed ? 0.68 : 1))
            .clipShape(Capsule())
    }
}
