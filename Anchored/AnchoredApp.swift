//
//  AnchoredApp.swift
//  Anchored
//
//  Created by Garrett Crane on 3/18/26.
//

import SwiftUI
import SwiftData

@main
struct AnchoredApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Verse.self])
    }
}
