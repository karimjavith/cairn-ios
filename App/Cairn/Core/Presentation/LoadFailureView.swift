//
//  LoadFailureView.swift
//  Cairn
//
//  Created by Codex on 17/08/2026.
//

import SwiftUI

struct LoadFailureView: View {
    let title: String
    let message: String
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "exclamationmark.triangle")
        } description: {
            Text(message)
        } actions: {
            Button("Retry", action: retry)
                .accessibilityLabel("Retry \(title)")
        }
    }
}
