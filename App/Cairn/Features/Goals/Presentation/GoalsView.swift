//
//  GoalsView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct GoalsView: View {
    var body: some View {
        ContentUnavailableView(
            "Goals",
            systemImage: "target",
            description: Text("Your goals will appear here.")
        )
        .navigationTitle("Goals")
    }
}
