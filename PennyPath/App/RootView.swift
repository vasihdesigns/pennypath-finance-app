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
        .sheet(isPresented: $quickAdd.showAddExpense) {
            ExpenseFormView()
        }
        .onAppear { PennyPathShortcuts.updateAppShortcutParameters() }
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
