//
//  CategoriesView.swift
//  Cairn
//
//  Created by Codex on 15/08/2026.
//

import SwiftUI

struct CategoriesView: View {
    var body: some View {
        ContentUnavailableView(
            "Categories",
            systemImage: "tag",
            description: Text("Your categories will appear here.")
        )
        .navigationTitle("Categories")
    }
}
