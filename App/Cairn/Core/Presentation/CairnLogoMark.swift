//
//  CairnLogoMark.swift
//  Cairn
//
//  Created by Codex on 24/08/2026.
//

import SwiftUI

struct CairnLogoMark: View {
    enum Scale {
        case compact
        case display

        var size: CGSize {
            switch self {
            case .compact:
                CGSize(width: 30, height: 28)
            case .display:
                CGSize(width: 160, height: 132)
            }
        }
    }

    let scale: Scale

    init(scale: Scale = .compact) {
        self.scale = scale
    }

    var body: some View {
        Image("CairnLogoMark")
            .resizable()
            .scaledToFit()
            .frame(width: scale.size.width, height: scale.size.height)
            .accessibilityLabel("Cairn")
    }
}
