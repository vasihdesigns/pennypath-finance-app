//
//  RootView.swift
//  PennyPath
//
//  Hosts the app shell: the Spectrum shell — four tabs (Net Worth, Expenses,
//  Goals, Insights), no Home, with a colour-per-card net-worth deck — plus the
//  storage-health banners and the quick-add sheet.
//

import SwiftUI
import SwiftData

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
    @Environment(AppStore.self) private var store
    // Fires when the "Add Expense" shortcut (e.g. Back Tap) runs.
    @State private var quickAdd = QuickAddCoordinator.shared
    // The reset notice is informational — once read it can go away.
    @State private var dismissedResetNotice = false

    var body: some View {
        @Bindable var quickAdd = quickAdd
        // The shipping app: the Spectrum shell — four tabs (Net Worth, Expenses,
        // Goals, Insights), no Home. Each net-worth card wears its own colour.
        return SpectrumRootView()
        .safeAreaInset(edge: .top, spacing: 0) {
            switch store.storeHealth {
            case .healthy:
                EmptyView()
            case .inMemoryFallback:
                storageWarning
            case .resetAfterFailure:
                if !dismissedResetNotice { resetNotice }
            }
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

    /// Shown when even a fresh on-disk database couldn't be created (e.g. the
    /// device is out of space): the app still works, but nothing entered now
    /// will survive a relaunch.
    private var storageWarning: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text("Storage problem — changes won't be saved. Free up space, then relaunch.")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, Theme.Space.sm)
        .background(Theme.red)
    }

    /// Shown once after the saved database couldn't be read and was set aside:
    /// the app saves normally again, but started from a blank slate.
    private var resetNotice: some View {
        HStack(spacing: Theme.Space.sm) {
            Image(systemName: "exclamationmark.triangle.fill")
                .accessibilityHidden(true)
            Text("Your saved data couldn't be read, so PennyPath started fresh. The old file was kept on this device.")
                .font(.caption.weight(.semibold))
                .multilineTextAlignment(.leading)
            Spacer(minLength: 0)
            Button {
                withAnimation { dismissedResetNotice = true }
            } label: {
                Image(systemName: "xmark")
                    .font(.caption.weight(.bold))
            }
            .accessibilityLabel("Dismiss")
        }
        .foregroundStyle(.white)
        .padding(.horizontal, Theme.Space.lg)
        .padding(.vertical, Theme.Space.sm)
        .background(Theme.gold)
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
