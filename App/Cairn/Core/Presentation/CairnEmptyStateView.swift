//
//  CairnEmptyStateView.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import SwiftUI

struct CairnEmptyStateView: View {
    let title: String
    let message: String
    let systemImage: String?
    let actionLabel: String?
    let action: (() -> Void)?

    init(
        title: String,
        message: String,
        systemImage: String? = nil,
        actionLabel: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.message = message
        self.systemImage = systemImage
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        VStack(alignment: .leading, spacing: CairnSpacing.medium) {
            HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.small) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }

                Text(title)
                    .font(.headline.weight(.semibold))
            }

            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let actionLabel, let action {
                Button(actionLabel, action: action)
                    .buttonStyle(CairnPrimaryButtonStyle())
                    .controlSize(.regular)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.vertical, CairnSpacing.medium)
    }
}
