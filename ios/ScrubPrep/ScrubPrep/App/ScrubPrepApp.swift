//
//  ScrubPrepApp.swift
//  ScrubPrep
//
//  Created by Edward Bender on 9/14/26.
//

import SwiftData
import SwiftUI
import ParseSwift

@main
struct ScrubPrepApp: App {
    init() {
        // On a genuinely fresh install, Application Support doesn't exist yet, so
        // SwiftData's first attempt to create its default.store there fails with
        // ENOENT — CoreData dumps a very verbose (but harmless) recovery log, then
        // creates the directory itself and succeeds anyway. Pre-creating it here
        // avoids that noisy first-launch failure/recovery dance entirely.
        if let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
        }

        // Harmless to initialize even in mock mode / with a placeholder Client Key —
        // no network call happens here. Needed once AppConfig.useMockData flips to
        // false for Phase 2 real-backend testing.
        ParseSwift.initialize(
            configuration: ParseConfiguration(
                applicationId: AppConfig.parseApplicationId,
                clientKey: AppConfig.parseClientKey,
                serverURL: AppConfig.parseServerURL
            )
        )
    }

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: [ScrubCase.self, PimpMeSession.self])
    }
}
