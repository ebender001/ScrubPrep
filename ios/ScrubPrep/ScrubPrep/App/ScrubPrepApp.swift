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
        .modelContainer(for: ScrubCase.self)
    }
}
