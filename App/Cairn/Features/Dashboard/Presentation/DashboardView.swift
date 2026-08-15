//
//  DashboardView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct DashboardView: View {
    var body: some View {
        ContentUnavailableView(
            "Dashboard",
            systemImage: "gauge",
            description: Text("Your financial overview will appear here.")
        )
        .navigationTitle("Dashboard")
    }
}
