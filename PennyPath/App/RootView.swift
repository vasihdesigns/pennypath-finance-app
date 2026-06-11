//
//  RootView.swift
//  PennyPath
//
//  The five tabs: Home, Net Worth, Spending, Goals, Coach.
//

import SwiftUI
import SwiftData

enum AppTab: Hashable {
    case home, netWorth, expenses, goals, coach
}

/// Which experimental Home shows while Developer Mode is on.
enum DevHomeStyle: String, CaseIterable {
    case premium, sophisticated, rings, verde, verdeLite, garden, sage
}

/// App appearance preference.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system, light, dark
    var id: String { rawValue }
    var label: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}

struct RootView: View {
    @State private var tab: AppTab = .home
    @Environment(AppStore.self) private var store
    // Developer Mode swaps in the experimental "premium" Home. Off = the real app.
    @AppStorage("developerMode") private var developerMode = false
    @AppStorage("devHomeStyle") private var devHomeStyle = DevHomeStyle.premium.rawValue
    // Fires when the "Add Expense" shortcut (e.g. Back Tap) runs.
    @State private var quickAdd = QuickAddCoordinator.shared

    var body: some View {
        @Bindable var quickAdd = quickAdd
        return Group {
            if developerMode, DevHomeStyle(rawValue: devHomeStyle) == .sage {
                // The Sage reskin replaces the whole shell: four tabs, no Home.
                SageRootView()
            } else {
                classicTabs
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            if store.isFallbackStore { storageWarning }
        }
        .sheet(isPresented: $quickAdd.showAddExpense) {
            // Quick-added expenses must not silently land in the throwaway
            // demo store — offer to switch back to real data first.
            if store.isDemo {
                DemoQuickAddNotice()
            } else {
                ExpenseFormView()
            }
        }
        .onAppear { PennyPathShortcuts.updateAppShortcutParameters() }
    }

    /// Shown when the on-disk database couldn't be opened: the app still works,
    /// but nothing entered now will survive a relaunch.
    private var storageWarning: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
            Text("Storage problem — changes won't be saved. Try relaunching, or free up space.")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, Theme.Space.sm)
        .background(Theme.red)
    }

    private var classicTabs: some View {
        TabView(selection: $tab) {
            NavigationStack {
                if developerMode {
                    switch DevHomeStyle(rawValue: devHomeStyle) ?? .premium {
                    case .premium: HomeViewPremium(selectedTab: $tab)
                    case .sophisticated: HomeViewSophisticated(selectedTab: $tab)
                    case .rings: HomeViewRings(selectedTab: $tab)
                    case .verde: HomeViewVerde(selectedTab: $tab)
                    case .verdeLite: HomeViewVerdeLite(selectedTab: $tab)
                    case .garden: HomeViewGarden(selectedTab: $tab)
                    case .sage: HomeView(selectedTab: $tab) // handled above; safe fallback
                    }
                } else {
                    HomeView(selectedTab: $tab)
                }
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(AppTab.home)

            NavigationStack { NetWorthView() }
                .tabItem { Label("Net Worth", systemImage: "chart.line.uptrend.xyaxis") }
                .tag(AppTab.netWorth)

            NavigationStack { ExpensesView() }
                .tabItem { Label("Spending", systemImage: "creditcard.fill") }
                .tag(AppTab.expenses)

            NavigationStack { GoalsView() }
                .tabItem { Label("Goals", systemImage: "target") }
                .tag(AppTab.goals)

            NavigationStack { CoachView() }
                .tabItem { Label("Coach", systemImage: "sparkles") }
                .tag(AppTab.coach)
        }
        .tint(Theme.ink)
    }
}

// MARK: - Quick add vs Demo Mode

/// What the Back Tap / Siri "Add Expense" shortcut shows while Demo Mode is on.
/// Adding into the demo world would silently throw the expense away later, so
/// the user picks: leave demo (the form reopens on real data) or add anyway.
private struct DemoQuickAddNotice: View {
    @Environment(AppStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var addToDemoAnyway = false

    var body: some View {
        if addToDemoAnyway {
            ExpenseFormView()
        } else {
            VStack(spacing: Theme.Space.lg) {
                Text("👀").font(.system(size: 44))
                Text("Demo Mode is on")
                    .font(.display(22))
                    .foregroundStyle(Theme.ink)
                Text("An expense added now would go into the demo world and vanish when Demo Mode turns off.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)

                VStack(spacing: Theme.Space.sm) {
                    Button("Turn off Demo Mode & add") {
                        // The app rebuilds onto the real store; the still-set
                        // quick-add flag re-presents the form there.
                        store.isDemo = false
                    }
                    .buttonStyle(PrimaryButtonStyle(tint: Theme.ink))

                    Button("Add to the demo anyway") { addToDemoAnyway = true }
                        .buttonStyle(SoftButtonStyle(tint: Theme.ink))

                    Button("Cancel") { dismiss() }
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .padding(.top, Theme.Space.xs)
                }
            }
            .padding(Theme.Space.xl)
            .presentationDetents([.medium])
        }
    }
}
