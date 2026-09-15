//
//  ScrubPrepApp.swift
//  ScrubPrep
//
//  Created by Edward Bender on 9/14/26.
//

import SwiftUI
import ParseSwift

@main
struct ScrubPrepApp: App {
    @StateObject private var authViewModel = AuthViewModel()

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
            Group {
                if authViewModel.currentUser != nil {
                    RootTabView()
                } else {
                    SignInView()
                }
            }
            .environmentObject(authViewModel)
            .alert("Account Created", isPresented: $authViewModel.showAccountCreatedAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Check your inbox to confirm your email address — you'll need it if you ever forget your password.")
            }
        }
    }
}
