//
//  CairnSectionHeading.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import SwiftUI

struct CairnSectionHeading: View {
    let title: String
    let subtitle: String?

    init(_ title: String, subtitle: String? = nil) {
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
            Text(title)
                .font(.headline.weight(.semibold))

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
