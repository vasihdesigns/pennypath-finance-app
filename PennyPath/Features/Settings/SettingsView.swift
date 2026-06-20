//
//  SettingsView.swift
//  PennyPath
//
//  Currency, sample data, and a short about section.
//

import SwiftUI
import SwiftData
import UIKit
import AppIntents

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL

    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("developerMode") private var developerMode = false
    @AppStorage("devHomeStyle") private var devHomeStyle = DevHomeStyle.premium.rawValue
    // Same default as PennyPathApp — the two must never disagree.
    @AppStorage("didCompleteOnboarding") private var didOnboard = false

    @Query private var accounts: [Account]
    @Query private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    @State private var showResetConfirm = false
    @State private var showClearConfirm = false
    @State private var demoOn = false
    @State private var versionTaps = 0
    @State private var showDevUnlocked = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: $demoOn) {
                        Label("Demo Mode", systemImage: "play.circle.fill")
                    }
                    .tint(Theme.gold)
                } header: {
                    Text("Demo")
                } footer: {
                    Text("Fills the app with a rich example world so you can explore or show it off. Your own data is kept safe and comes right back when you turn this off.")
                }

                Section("Appearance") {
                    Picker("Appearance", selection: $appearance) {
                        ForEach(AppAppearance.allCases) { mode in
                            Text(mode.label).tag(mode.rawValue)
                        }
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    NavigationLink {
                        CurrencyPickerView(selection: $currencyCode)
                    } label: {
                        HStack {
                            Text("Currency")
                            Spacer()
                            Text(currencyCode).foregroundStyle(Theme.inkSecondary)
                        }
                    }
                } header: {
                    Text("Currency")
                } footer: {
                    Text("Changes the symbol your numbers are shown with — amounts you've entered aren't converted. Investment values are converted to the new currency on their next price refresh.")
                }

                Section {
                    SiriTipView(intent: AddExpenseIntent())
                        .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                    ShortcutsLink()
                    Button {
                        openURL(URL(string: UIApplication.openSettingsURLString)!)
                    } label: {
                        Label("Open iOS Settings (for Back Tap)", systemImage: "gearshape.fill")
                    }
                } header: {
                    Text("Quick add shortcut")
                } footer: {
                    Text("The “Add Expense” shortcut is already built in — nothing to set up. Tap **Add to Siri** above and just say it, or use the Shortcuts button to drop it on your Home Screen.\n\nTo fire it by tapping the back of your iPhone, iOS requires you to switch it on yourself (no app is allowed to change this): Settings → Accessibility → Touch → Back Tap → Double Tap → **Add Expense**.")
                }

                Section {
                    Button {
                        showResetConfirm = true
                    } label: {
                        Label("Load sample data", systemImage: "sparkles")
                    }
                    .disabled(store.isDemo)
                    Button(role: .destructive) {
                        showClearConfirm = true
                    } label: {
                        Label("Clear everything", systemImage: "trash")
                    }
                    .disabled(store.isDemo)
                } header: {
                    Text("Your data")
                } footer: {
                    Text(store.isDemo
                         ? "Turn off Demo Mode to manage your own data."
                         : "Sample data fills the app with example accounts, spending, and goals so you can explore. Clearing removes everything and starts you fresh.")
                }

                Section {
                    LabeledContent("App", value: "PennyPath")
                    LabeledContent("Version", value: appVersion)
                        .contentShape(Rectangle())
                        .onTapGesture { registerVersionTap() }
                } header: {
                    Text("About")
                } footer: {
                    Text("Your money coach runs entirely on this device — your balances, spending, and goals never leave your phone. The only network use is fetching public market prices and exchange rates for the investments and currencies you add, and looking up an app's name and icon when you type a subscription.")
                }

                Section {
                    Toggle(isOn: $developerMode) {
                        Label("Developer Mode", systemImage: "hammer.fill")
                    }
                    .tint(Theme.ink)
                } header: {
                    Text("Advanced")
                } footer: {
                    Text("Tools for tinkering — replay the intro and peek at what's stored on the device.")
                }

                if developerMode {
                    Section {
                        Picker("Home style", selection: $devHomeStyle) {
                            Text("Premium (bold)").tag(DevHomeStyle.premium.rawValue)
                            Text("Sophisticated").tag(DevHomeStyle.sophisticated.rawValue)
                            Text("Activity Rings").tag(DevHomeStyle.rings.rawValue)
                            Text("Verde (full reskin)").tag(DevHomeStyle.verde.rawValue)
                            Text("Verde (palette + type)").tag(DevHomeStyle.verdeLite.rawValue)
                            Text("Money Garden 🌱").tag(DevHomeStyle.garden.rawValue)
                            Text("Spectrum (colour-per-card · stacked)").tag(DevHomeStyle.spectrum.rawValue)
                        }
                        Button {
                            replayOnboarding()
                        } label: {
                            Label("Replay onboarding", systemImage: "play.rectangle.fill")
                        }
                        Button {
                            resetFirstRun()
                        } label: {
                            Label("Reset first-run state", systemImage: "arrow.counterclockwise")
                        }
                    } header: {
                        Text("Developer")
                    } footer: {
                        Text("Replay shows the welcome screens again. Reset also clears the first-run sample-data flag (applies on next launch).")
                    }

                    Section("Diagnostics") {
                        LabeledContent("Active store", value: storeStatus)
                        LabeledContent("Accounts", value: "\(accounts.count)")
                        LabeledContent("Expenses", value: "\(expenses.count)")
                        LabeledContent("Goals", value: "\(goals.count)")
                        LabeledContent("Budgets", value: "\(budgets.count)")
                        LabeledContent("Build", value: buildNumber)
                        LabeledContent("iOS", value: UIDevice.current.systemVersion)
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .tint(Theme.ink)
            .onAppear { demoOn = store.isDemo }
            .onChange(of: demoOn) { _, newValue in
                guard newValue != store.isDemo else { return }
                // Close this sheet first, then swap stores on the next runloop so
                // the tree rebuild doesn't fight the in-flight toggle interaction.
                dismiss()
                DispatchQueue.main.async { store.isDemo = newValue }
            }
            .confirmationDialog("Replace everything with sample data?",
                                isPresented: $showResetConfirm, titleVisibility: .visible) {
                Button("Load sample data", role: .destructive) {
                    SampleData.reset(in: context)
                    dismiss()
                }
            } message: {
                Text("This clears your current data and loads examples.")
            }
            .confirmationDialog("Clear all your data?",
                                isPresented: $showClearConfirm, titleVisibility: .visible) {
                Button("Clear everything", role: .destructive) {
                    SampleData.clear(in: context)
                    dismiss()
                }
            } message: {
                Text("This can't be undone.")
            }
            .alert("Developer Mode unlocked 🛠️", isPresented: $showDevUnlocked) {
                Button("Nice", role: .cancel) {}
            } message: {
                Text("Developer tools are now available below.")
            }
        }
    }

    private var storeStatus: String {
        if store.isDemo { return "Demo · in-memory" }
        switch store.storeHealth {
        case .healthy: return "Real · on disk"
        case .resetAfterFailure: return "⚠️ Reset · fresh on disk"
        case .inMemoryFallback: return "⚠️ Fallback · in-memory"
        }
    }

    // MARK: Developer actions

    private func registerVersionTap() {
        guard !developerMode else { return }
        versionTaps += 1
        if versionTaps >= 5 {
            versionTaps = 0
            developerMode = true
            Haptics.success()
            showDevUnlocked = true
        }
    }

    private func replayOnboarding() {
        // Close Settings first so the onboarding overlay isn't hidden behind it.
        dismiss()
        DispatchQueue.main.async { didOnboard = false }
    }

    private func resetFirstRun() {
        dismiss()
        DispatchQueue.main.async {
            UserDefaults.standard.removeObject(forKey: SampleData.seededKey)
            didOnboard = false
        }
    }
}
