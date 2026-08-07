//
//  RootView.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import SwiftUI

struct RootView: View {
    var body: some View {
        VStack(spacing: 12) {
            Text("Cairn")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Personal finance, privately by design.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Cairn. Personal finance, privately by design.")
    }
}
