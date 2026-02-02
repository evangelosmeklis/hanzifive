//
//  xuehanziApp.swift
//  xuehanzi
//
//  Created by Evangelos Meklis on 1/2/26.
//

import SwiftUI
import SwiftData

@main
struct xuehanziApp: App {
    private let modelContainer: ModelContainer

    init() {
        do {
            let schema = Schema([Word.self, ReviewState.self, LevelAchievement.self])
            modelContainer = try ModelContainer(for: schema)
            AppDataSeeder.seedIfNeeded(modelContext: modelContainer.mainContext)
        } catch {
            fatalError("Failed to set up data store: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
