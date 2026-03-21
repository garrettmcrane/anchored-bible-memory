//
//  AnchoredApp.swift
//  Anchored
//
//  Created by Garrett Crane on 3/18/26.
//

import SwiftUI

@main
struct AnchoredApp: App {
    @StateObject private var settingsController = UserSettingsController()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsController)
                .preferredColorScheme(settingsController.preferredColorScheme)
        }
    }
}
