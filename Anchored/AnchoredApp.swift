//
//  AnchoredApp.swift
//  Anchored
//
//  Created by Garrett Crane on 3/18/26.
//

import CoreText
import SwiftUI

@main
struct AnchoredApp: App {
    @StateObject private var settingsController = UserSettingsController()

    init() {
        FontRegistrar.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(settingsController)
                .preferredColorScheme(settingsController.preferredColorScheme)
        }
    }
}

private enum FontRegistrar {
    static func registerBundledFonts() {
        let candidateURLs = [
            Bundle.main.url(forResource: "Newsreader-Variable", withExtension: "ttf", subdirectory: "Fonts"),
            Bundle.main.url(forResource: "Newsreader-Variable", withExtension: "ttf")
        ].compactMap { $0 }

        for fontURL in candidateURLs {
            CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, nil)
        }
    }
}
