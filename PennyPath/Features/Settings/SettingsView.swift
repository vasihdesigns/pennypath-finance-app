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
import StoreKit

struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @Environment(AppStore.self) private var store
    @Environment(\.openURL) private var openURL
    @Environment(\.requestReview) private var requestReview

    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    @AppStorage("appearance") private var appearance = AppAppearance.system.rawValue
    @AppStorage("developerMode") private var developerMode = false
    @AppStorage(AppLockManager.enabledKey) private var appLockEnabled = false
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
    @State private var exportItem: ExportFile?
    @State private var exportFailed = false

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }

    var body: some View {
        @Bindable var store = store
        return NavigationStack {
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
                    Toggle(isOn: $appLockEnabled) {
                        Label("Require Face ID / Touch ID", systemImage: "faceid")
                    }
                    .tint(Theme.ink)
                } header: {
                    Text("Privacy & Security")
                } footer: {
                    Text("Locks PennyPath so your balances stay hidden in the app switcher and open only with Face ID, Touch ID, or your passcode.")
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
                    Toggle(isOn: $store.iCloudSyncEnabled) {
                        Label("iCloud Sync", systemImage: "icloud")
                    }
                    .tint(Theme.ink)
                    .disabled(store.isDemo)
                    Button {
                        exportData()
                    } label: {
                        Label("Export data (.json)", systemImage: "square.and.arrow.up")
                    }
                    .disabled(store.isDemo)
                } header: {
                    Text("Backup & sync")
                } footer: {
                    Text(store.isDemo
                         ? "Turn off Demo Mode to back up your own data."
                         : "iCloud Sync keeps a private copy of your data in your iCloud and in sync across your devices. Export saves a JSON copy you can keep or move anywhere.")
                }

                Section {
                    Link(destination: SupportLinks.privacyPolicy) {
                        Label("Privacy Policy", systemImage: "hand.raised")
                    }
                    Link(destination: SupportLinks.terms) {
                        Label("Terms of Use", systemImage: "doc.text")
                    }
                    Button {
                        if let url = SupportLinks.supportMailURL(appVersion: appVersion, build: buildNumber) {
                            openURL(url)
                        }
                    } label: {
                        Label("Contact Support", systemImage: "envelope")
                    }
                    Button {
                        requestReview()
                    } label: {
                        Label("Rate PennyPath", systemImage: "star")
                    }
                } header: {
                    Text("Help & legal")
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
            .sheet(item: $exportItem) { item in
                ActivityView(url: item.url)
            }
            .alert("Couldn't export", isPresented: $exportFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong preparing your data file. Please try again.")
            }
            .onChange(of: appLockEnabled) { _, enabled in
                // Disabling reveals the app immediately; enabling takes effect
                // the next time PennyPath leaves the foreground.
                if !enabled { AppLockManager.shared.isEnabled = false }
            }
        }
    }

    private func exportData() {
        do {
            let url = try DataExport.writeTemporaryFile(from: context)
            exportItem = ExportFile(url: url)
        } catch {
            exportFailed = true
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

// MARK: - Data export sharing

/// A shareable export file, wrapped so `.sheet(item:)` can present the system
/// share sheet once the JSON has been written.
struct ExportFile: Identifiable {
    let id = UUID()
    let url: URL
}

/// Bridges `UIActivityViewController` (the system share sheet) into SwiftUI so
/// the exported backup can be saved to Files, AirDropped, or sent anywhere.
struct ActivityView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: [url], applicationActivities: nil)
    }
    func updateUIViewController(_ controller: UIActivityViewController, context: Context) {}
}
