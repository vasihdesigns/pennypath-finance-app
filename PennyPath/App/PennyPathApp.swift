//
//  PennyPathApp.swift
//  PennyPath
//
//  A clean, simple personal-finance app: Net Worth, Spending, Goals,
//  and an on-device AI money coach.
//

import SwiftUI
import SwiftData

@main
struct PennyPathApp: App {
    @State private var store = AppStore()
    @AppStorage("didCompleteOnboarding") private var didOnboard = false
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue

    var body: some Scene {
        WindowGroup {
            ZStack {
                RootView()
                    // Switching stores (Demo Mode) rebuilds the tree so every
                    // @Query re-reads the new container and no stale objects linger.
                    .id(store.isDemo)
                    .modelContainer(store.container)
                    .environment(store)

                if !didOnboard {
                    OnboardingView { didOnboard = true }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: didOnboard)
            .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
        }
    }
}
