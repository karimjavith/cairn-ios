//
//  CairnSurface.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import SwiftUI

enum CairnSurfaceProminence {
    case subtle
    case elevated
}

struct CairnSurfaceStyle: ViewModifier {
    let prominence: CairnSurfaceProminence

    func body(content: Content) -> some View {
        content
            .padding(CairnSpacing.large)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private var background: some ShapeStyle {
        switch prominence {
        case .subtle:
            CairnColor.lavenderSurface
        case .elevated:
            CairnColor.elevatedSurface
        }
    }
}

extension View {
    func cairnSurface(_ prominence: CairnSurfaceProminence = .subtle) -> some View {
        modifier(CairnSurfaceStyle(prominence: prominence))
    }
}
