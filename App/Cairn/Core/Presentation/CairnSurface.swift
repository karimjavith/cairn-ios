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
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(Color.primary.opacity(prominence == .subtle ? 0.08 : 0.12))
            }
    }

    private var background: some ShapeStyle {
        switch prominence {
        case .subtle:
            Color(.secondarySystemBackground)
        case .elevated:
            Color(.tertiarySystemBackground)
        }
    }
}

extension View {
    func cairnSurface(_ prominence: CairnSurfaceProminence = .subtle) -> some View {
        modifier(CairnSurfaceStyle(prominence: prominence))
    }
}
