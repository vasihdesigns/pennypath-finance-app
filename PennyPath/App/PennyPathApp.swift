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
    @State private var lock = AppLockManager.shared
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

                // The lock screen sits above everything (even onboarding) so no
                // content is visible until the owner authenticates.
                if lock.isLocked {
                    AppLockView()
                        .transition(.opacity)
                        .zIndex(2)
                }
            }
            .animation(.easeInOut(duration: 0.4), value: didOnboard)
            // The lock cover is applied WITHOUT an implicit animation here, so it
            // snaps into place the instant the app goes inactive — before iOS takes
            // the app-switcher snapshot. A fade-in would let balances bleed through
            // that snapshot for a frame. The unlock fade is driven by an explicit
            // `withAnimation` in `AppLockManager` instead (see AppLock.swift).
            .preferredColorScheme((AppAppearance(rawValue: appearance) ?? .system).colorScheme)
            .onChange(of: scenePhase) { _, phase in
                switch phase {
                case .active:
                    // One daily net-worth point, recorded no matter which tab
                    // the user lives in (views also record when balances change).
                    NetWorthHistory.record(in: store.container.mainContext)
                    // Returning to the app behind the lock screen re-prompts.
                    if lock.isLocked { Task { await lock.authenticate() } }
                case .background, .inactive:
                    // Hide contents the instant we leave the foreground, so
                    // balances don't show in the app switcher.
                    lock.lockForBackground()
                @unknown default:
                    break
                }
            }
        }
    }
}
