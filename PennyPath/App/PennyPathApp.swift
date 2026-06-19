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
    @Environment(\.scenePhase) private var scenePhase
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
                    SpectrumOnboardingView { didOnboard = true }
                        .transition(.opacity)
                        .zIndex(1)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: didOnboard)
            .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
            // One daily net-worth point, recorded no matter which tab the
            // user lives in (views also record when balances change).
            .onChange(of: scenePhase) { _, phase in
                if phase == .active {
                    NetWorthHistory.record(in: store.container.mainContext)
                }
            }
        }
    }
}
