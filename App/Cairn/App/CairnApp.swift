//
//  CairnApp.swift
//  Cairn
//
//  Created by Karim Sheikh on 07/08/2026.
//

import SwiftUI
import SwiftData

@main
struct CairnApp: App {
    private let modelContainer: ModelContainer = {
        let schema = Schema()
        let configuration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            fatalError("Unable to create SwiftData model container: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(modelContainer)
    }
}
