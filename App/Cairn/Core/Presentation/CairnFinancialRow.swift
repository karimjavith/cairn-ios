//
//  CairnFinancialRow.swift
//  Cairn
//
//  Created by Codex on 23/08/2026.
//

import SwiftUI

struct CairnFinancialRow<Leading: View>: View {
    let title: String
    let metadata: String?
    let trailing: String
    let status: String?
    let accessibilityLabel: String
    let leading: () -> Leading

    init(
        title: String,
        metadata: String? = nil,
        trailing: String,
        status: String? = nil,
        accessibilityLabel: String,
        @ViewBuilder leading: @escaping () -> Leading
    ) {
        self.title = title
        self.metadata = metadata
        self.trailing = trailing
        self.status = status
        self.accessibilityLabel = accessibilityLabel
        self.leading = leading
    }

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: CairnSpacing.medium) {
            leading()
                .frame(width: 28, alignment: .leading)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: CairnSpacing.extraSmall) {
                Text(title)
                    .font(.body.weight(.medium))

                if let metadata {
                    Text(metadata)
                        .font(.subheadline)
                        .foregroundStyle(CairnColor.textSecondary)
                        .lineLimit(2)
                }
            }

            Spacer(minLength: CairnSpacing.medium)

            VStack(alignment: .trailing, spacing: CairnSpacing.extraSmall) {
                Text(trailing)
                    .cairnRowAmount()

                if let status {
                    Text(status)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(CairnColor.textSecondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, CairnSpacing.small)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilityLabel)
    }
}

extension CairnFinancialRow where Leading == EmptyView {
    init(
        title: String,
        metadata: String? = nil,
        trailing: String,
        status: String? = nil,
        accessibilityLabel: String
    ) {
        self.init(
            title: title,
            metadata: metadata,
            trailing: trailing,
            status: status,
            accessibilityLabel: accessibilityLabel
        ) {
            EmptyView()
        }
    }
}
