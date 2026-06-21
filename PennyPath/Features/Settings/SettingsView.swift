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
import UniformTypeIdentifiers

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
    @Query(filter: #Predicate<Account> { $0.isArchived }) private var archivedAccounts: [Account]
    @Query(filter: #Predicate<Goal> { $0.isArchived }) private var archivedGoals: [Goal]

    @State private var showResetConfirm = false
    // Drives the guarded multi-step delete flow (intro → backup choice →
    // final confirm). `nil` means no step is showing.
    @State private var clearStep: ClearStep?
    // True while the share-sheet backup is part of the delete flow, so dismissing
    // it advances to the final confirmation instead of just closing.
    @State private var pendingClearAfterBackup = false
    @State private var demoOn = false
    // A demo switch the user asked for, applied only once this sheet is gone.
    @State private var pendingDemo: Bool?
    @State private var versionTaps = 0
    @State private var showDevUnlocked = false
    @State private var exportItem: ExportFile?
    @State private var exportFailed = false
    @State private var showPaywall = false
    @State private var showImportPicker = false
    @State private var pendingImportURL: URL?
    @State private var importSummary: String?
    @State private var importFailed = false
    // Result of a standalone "Back up to iCloud" (success or failure text).
    @State private var cloudBackupMessage: String?

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
    }
    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
    }
    private var archivedCount: Int { archivedAccounts.count + archivedGoals.count }

    var body: some View {
        @Bindable var store = store
        return NavigationStack {
            Form {
                topSections
                quickAddSection
                dataSection
                backupSection
                helpLegalSection
                aboutSection
                advancedSection
                developerSections
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
                // Defer the actual store swap until this sheet has fully
                // disappeared. Swapping the SwiftData container while Settings is
                // still on screen re-evaluates its @Query (archivedAccounts)
                // against the torn-down context and traps (EXC_BREAKPOINT).
                // onDisappear runs after the sheet is gone, so nothing here
                // observes the old store during the swap.
                pendingDemo = newValue
                dismiss()
            }
            .onDisappear {
                guard let target = pendingDemo else { return }
                pendingDemo = nil
                // Apply on the next runloop, once this sheet is fully gone, so the
                // SwiftData container swap never overlaps Settings' own teardown.
                DispatchQueue.main.async { store.isDemo = target }
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
            // The guarded multi-step delete flow lives in its own modifier so the
            // Form's modifier chain stays light enough for the type-checker.
            .modifier(ClearFlowDialogs(step: $clearStep,
                                       mentionsCloud: clearMentionsCloud,
                                       advance: advanceClear,
                                       backup: backupThenDelete,
                                       clear: performClear))
            .alert("Developer Mode unlocked 🛠️", isPresented: $showDevUnlocked) {
                Button("Nice", role: .cancel) {}
            } message: {
                Text("Developer tools are now available below.")
            }
            .sheet(item: $exportItem, onDismiss: {
                // If this export was the backup step of the delete flow, move on
                // to the final confirmation now that the share sheet is closed.
                guard pendingClearAfterBackup else { return }
                pendingClearAfterBackup = false
                advanceClear(to: .confirmDelete)
            }) { item in
                ActivityView(url: item.url)
            }
            .alert("iCloud Backup", isPresented: cloudBackupShown) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(cloudBackupMessage ?? "")
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
            .alert("Couldn't export", isPresented: $exportFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Something went wrong preparing your data file. Please try again.")
            }
            .fileImporter(isPresented: $showImportPicker, allowedContentTypes: [.json]) { result in
                switch result {
                case .success(let url): pendingImportURL = url
                case .failure: importFailed = true
                }
            }
            .confirmationDialog("Replace your data with this backup?",
                                isPresented: importConfirmShown, titleVisibility: .visible) {
                Button("Replace everything", role: .destructive) { runImport() }
                Button("Cancel", role: .cancel) { pendingImportURL = nil }
            } message: {
                Text("This erases what's in PennyPath now and restores the backup in its place. If you're not sure, export your current data first.")
            }
            .alert("Backup restored", isPresented: importSuccessShown) {
                Button("OK") { importSummary = nil; dismiss() }
            } message: {
                Text(importSummary ?? "")
            }
            .alert("Couldn't import", isPresented: $importFailed) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("That file couldn't be read as a PennyPath backup. Make sure it's a .json file you exported from PennyPath.")
            }
            .onChange(of: appLockEnabled) { _, enabled in
                // Disabling reveals the app immediately; enabling takes effect
                // the next time PennyPath leaves the foreground.
                if !enabled { AppLockManager.shared.isEnabled = false }
            }
        }
    }

    // Extracted from the Form so the body stays light enough for the type-checker.

    @ViewBuilder private var topSections: some View {
        Section {
            PlusUpsellRow { showPaywall = true }
                .listRowInsets(EdgeInsets())
                .listRowBackground(Color.clear)
        }

        Section {
            NavigationLink {
                SearchView()
            } label: {
                Label("Search your items", systemImage: "magnifyingglass")
            }
        } footer: {
            Text("Find any account, investment, goal, expense, or upcoming payment you've added.")
        }

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
    }

    @ViewBuilder private var quickAddSection: some View {
        Section {
            SiriTipView(intent: AddExpenseIntent())
                .listRowInsets(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
            ShortcutsLink()
            Button {
                openURL(URL(string: UIApplication.openSettingsURLString)!)
            } label: {
                Label("Open the Settings app", systemImage: "gearshape.fill")
            }
        } header: {
            Text("Quick add shortcut")
        } footer: {
            // Back Tap can't be set by an app and has no direct link, so be
            // honest about it: the button just opens the Settings app, and
            // the steps below get the user the rest of the way.
            Text("The **Add Expense** shortcut is already built in — pick how to trigger it:\n\n•  **Say it:** tap *Add to Siri* above, then ask Siri.\n•  **Home Screen:** tap *Shortcuts* to add it as a tappable icon.\n•  **Back Tap:** double-tap the back of your iPhone. iOS won't let an app turn this on (and there's no link straight to it), so open the Settings app and go to **Accessibility → Touch → Back Tap → Double Tap → Add Expense**.")
        }
    }

    @ViewBuilder private var helpLegalSection: some View {
        Section {
            NavigationLink {
                UserGuideView()
            } label: {
                Label("User Guide", systemImage: "book")
            }
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
    }

    @ViewBuilder private var aboutSection: some View {
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
    }

    @ViewBuilder private var advancedSection: some View {
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
    }

    @ViewBuilder private var developerSections: some View {
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

    @ViewBuilder private var dataSection: some View {
        Section {
            NavigationLink {
                ArchivedView()
            } label: {
                HStack {
                    Label("Archived", systemImage: "archivebox")
                    Spacer()
                    Text(archivedCount == 0 ? "None" : "\(archivedCount)")
                        .foregroundStyle(Theme.inkSecondary)
                }
            }
            .disabled(store.isDemo)
            Button {
                showResetConfirm = true
            } label: {
                Label("Load sample data", systemImage: "sparkles")
            }
            .disabled(store.isDemo)
            Button(role: .destructive) {
                clearStep = .intro
            } label: {
                Label("Reset & clear everything", systemImage: "trash")
            }
            .disabled(store.isDemo)
        } header: {
            Text("Your data")
        } footer: {
            Text(store.isDemo
                 ? "Turn off Demo Mode to manage your own data."
                 : "Archived items are tucked away but kept. Sample data fills the app with examples to explore. Resetting removes everything — including anything archived — and starts you fresh.")
        }
    }

    @ViewBuilder private var backupSection: some View {
        @Bindable var store = store
        Section {
            Toggle(isOn: $store.iCloudSyncEnabled) {
                Label("iCloud Sync", systemImage: "icloud")
            }
            .tint(Theme.ink)
            .disabled(store.isDemo)
            Button {
                backUpToICloud()
            } label: {
                Label("Back up to iCloud", systemImage: "icloud.and.arrow.up")
            }
            .disabled(store.isDemo)
            Button {
                restoreLatestFromICloud()
            } label: {
                Label("Restore latest from iCloud", systemImage: "icloud.and.arrow.down")
            }
            .disabled(store.isDemo)
            Button {
                exportData()
            } label: {
                Label("Export data (.json)", systemImage: "square.and.arrow.up")
            }
            .disabled(store.isDemo)
            Button {
                showImportPicker = true
            } label: {
                Label("Import data (.json)", systemImage: "square.and.arrow.down")
            }
            .disabled(store.isDemo)
        } header: {
            Text("Backup & sync")
        } footer: {
            Text(store.isDemo
                 ? "Turn off Demo Mode to back up your own data."
                 : "iCloud Sync mirrors your data across your devices — but it's a sync, not a safety net: a delete syncs everywhere too. **Back up to iCloud** saves a separate snapshot that survives a reset, and **Restore latest from iCloud** brings it back. Export saves a JSON copy anywhere; Import replaces everything currently in the app.")
        }
    }

    private func exportData() {
        do {
            let url = try DataExport.writeTemporaryFile(from: context)
            exportItem = ExportFile(url: url)
        } catch {
            // A failed backup must never silently fall through to the delete.
            pendingClearAfterBackup = false
            exportFailed = true
        }
    }

    // MARK: Guarded delete flow

    /// Steps the user passes through before any data is erased. See the
    /// `.confirmationDialog`s in `body` for the copy on each.
    enum ClearStep: Equatable { case intro, backupChoice, confirmNoBackup, confirmDelete }

    /// True when the live store is mirroring to iCloud, so the warnings can be
    /// honest that clearing also wipes the cloud copy and other devices.
    private var clearMentionsCloud: Bool { store.iCloudSyncEnabled && !store.isDemo }

    /// Dismiss the current dialog, then present the next on the following runloop
    /// so SwiftUI doesn't drop the second sheet mid-transition.
    private func advanceClear(to step: ClearStep) {
        clearStep = nil
        DispatchQueue.main.async { clearStep = step }
    }

    /// "Back up to iCloud" → write a snapshot straight into the app's iCloud Drive
    /// folder, then advance to the final confirm. Falls back to the share sheet
    /// ("Save to Files") when iCloud Drive isn't available.
    private func backupThenDelete() {
        clearStep = nil
        // Encode on the main actor (it reads the model context); write off-main.
        let data: Data
        do {
            data = try DataExport.jsonData(from: context)
        } catch {
            // Can't produce a backup — abort rather than delete unprotected.
            exportFailed = true
            return
        }
        Task { @MainActor in
            if await CloudBackup.isAvailable() {
                do {
                    try await CloudBackup.writeBackup(data)
                    Haptics.success()
                    advanceClear(to: .confirmDelete)
                } catch {
                    shareSheetBackupFallback()
                }
            } else {
                shareSheetBackupFallback()
            }
        }
    }

    /// iCloud Drive unavailable → offer the share sheet so the user can still
    /// "Save to Files" before the delete proceeds.
    private func shareSheetBackupFallback() {
        pendingClearAfterBackup = true
        exportData()
    }

    /// Standalone, proactive backup from the Backup & sync section.
    private func backUpToICloud() {
        let data: Data
        do {
            data = try DataExport.jsonData(from: context)
        } catch {
            cloudBackupMessage = "Couldn't prepare your data for backup. Please try again."
            return
        }
        Task { @MainActor in
            do {
                let url = try await CloudBackup.writeBackup(data)
                Haptics.success()
                cloudBackupMessage = "Saved “\(url.lastPathComponent)” to iCloud Drive → PennyPath. You can re-import it anytime — even after resetting."
            } catch {
                cloudBackupMessage = (error as? CloudBackup.BackupError)?.errorDescription
                    ?? "Couldn't save to iCloud Drive. Check your connection and try again."
            }
        }
    }

    private var cloudBackupShown: Binding<Bool> {
        Binding(get: { cloudBackupMessage != nil }, set: { if !$0 { cloudBackupMessage = nil } })
    }

    /// Pull the most recent iCloud backup, then hand it to the same
    /// replace-confirmation + import path the file picker uses, so restoring
    /// always asks before overwriting.
    private func restoreLatestFromICloud() {
        Task { @MainActor in
            do {
                guard let url = try await CloudBackup.downloadLatestBackup() else {
                    cloudBackupMessage = "No iCloud backup found yet. Tap “Back up to iCloud” to make one."
                    return
                }
                pendingImportURL = url   // → "Replace your data with this backup?" → runImport()
            } catch {
                cloudBackupMessage = (error as? CloudBackup.BackupError)?.errorDescription
                    ?? "Couldn't reach your iCloud backup. Check your connection and try again."
            }
        }
    }

    /// The single place data is actually erased — reached only past the guards.
    private func performClear() {
        clearStep = nil
        SampleData.clear(in: context)
        dismiss()
    }

    private func runImport() {
        guard let url = pendingImportURL else { return }
        pendingImportURL = nil
        // A document picked from Files lives outside the app's sandbox.
        let scoped = url.startAccessingSecurityScopedResource()
        defer { if scoped { url.stopAccessingSecurityScopedResource() } }
        do {
            let data = try Data(contentsOf: url)
            let s = try DataExport.importSnapshot(from: data, into: context)
            Haptics.success()
            func n(_ count: Int, _ noun: String) -> String { "\(count) \(noun)\(count == 1 ? "" : "s")" }
            importSummary = "Restored \(n(s.accounts, "account")), \(n(s.expenses, "expense")), \(n(s.goals, "goal")), and \(n(s.payments, "upcoming payment"))."
        } catch {
            importFailed = true
        }
    }

    // Drive the replace-confirmation and success alerts off their optional state.
    private var importConfirmShown: Binding<Bool> {
        Binding(get: { pendingImportURL != nil }, set: { if !$0 { pendingImportURL = nil } })
    }
    private var importSuccessShown: Binding<Bool> {
        Binding(get: { importSummary != nil }, set: { if !$0 { importSummary = nil } })
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

// MARK: - Guarded delete flow dialogs

/// The "Reset & clear everything" confirmation chain, extracted from
/// `SettingsView.body` so its long modifier list doesn't blow the Swift
/// type-checker. Drives four sequential dialogs off a single `ClearStep?`:
/// intro → backup yes/no → (disclaimer | post-backup) → erase.
private struct ClearFlowDialogs: ViewModifier {
    @Binding var step: SettingsView.ClearStep?
    let mentionsCloud: Bool
    let advance: (SettingsView.ClearStep) -> Void
    let backup: () -> Void
    let clear: () -> Void

    /// One-way binding from `step` to a single dialog's presented flag.
    private func shown(_ s: SettingsView.ClearStep) -> Binding<Bool> {
        Binding(get: { step == s },
                set: { isShown in if !isShown && step == s { step = nil } })
    }

    func body(content: Content) -> some View {
        content
            // Step 1 — what's about to happen (and that iCloud is included).
            .confirmationDialog("Reset & clear everything?",
                                isPresented: shown(.intro), titleVisibility: .visible) {
                Button("Continue") { advance(.backupChoice) }
                Button("Cancel", role: .cancel) { step = nil }
            } message: {
                Text(mentionsCloud
                     ? "This permanently erases every account, expense, goal, and budget — including anything archived. Because iCloud Sync is on, it also clears the copy in your iCloud and on your other devices. To hide an account without losing it, archive it instead."
                     : "This permanently erases every account, expense, goal, and budget — including anything archived. It can't be undone. To hide an account without losing it, archive it instead.")
            }
            // Step 2 — the iCloud-backup yes/no.
            .confirmationDialog("Back up your data first?",
                                isPresented: shown(.backupChoice), titleVisibility: .visible) {
                Button("Back up to iCloud") { backup() }
                Button("Delete without a backup", role: .destructive) { advance(.confirmNoBackup) }
                Button("Cancel", role: .cancel) { step = nil }
            } message: {
                Text("Save a backup you can re-import later. Tap Back up, then choose “Save to Files” → iCloud Drive. Without a backup there's no way to undo this.")
            }
            // Step 3a — the disclaimer when they decline a backup.
            .confirmationDialog("Delete without a backup?",
                                isPresented: shown(.confirmNoBackup), titleVisibility: .visible) {
                Button("Delete permanently", role: .destructive) { clear() }
                Button("Cancel", role: .cancel) { step = nil }
            } message: {
                Text(mentionsCloud
                     ? "Your data will be permanently erased from this device and your iCloud — with no backup and no way to get it back."
                     : "Your data will be permanently erased from this device — with no backup and no way to get it back.")
            }
            // Step 3b — final confirm, reached only after a backup was saved.
            .confirmationDialog("Delete everything now?",
                                isPresented: shown(.confirmDelete), titleVisibility: .visible) {
                Button("Delete everything", role: .destructive) { clear() }
                Button("Cancel", role: .cancel) { step = nil }
            } message: {
                Text("Your backup is saved. This erases all data from PennyPath — you can restore it later with Import data.")
            }
    }
}

// MARK: - Plus upsell banner

/// The jewel-tone "PennyPath Plus" banner that sits at the top of Settings and
/// opens the paywall. A gradient card cut from the Spectrum deck palette so it
/// stands apart from the plain Form rows below it.
private struct PlusUpsellRow: View {
    var onTap: () -> Void
    @State private var store = Store.shared

    private let jewels: [Color] = SpectrumMoneyKind.allCases.map(\.fill)

    var body: some View {
        Button {
            Haptics.tap()
            onTap()
        } label: {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(.white.opacity(0.18))
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .frame(width: 46, height: 46)
                VStack(alignment: .leading, spacing: 3) {
                    Text("PennyPath Plus")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                    Text(store.isPlus ? "You're a member — thank you!" : "Unlock everything — try it free")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.85))
                }
                Spacer(minLength: 8)
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(
                LinearGradient(colors: jewels,
                               startPoint: .topLeading, endPoint: .bottomTrailing)
            )
            .overlay(
                LinearGradient(colors: [.white.opacity(0.18), .clear],
                               startPoint: .top, endPoint: .center)
            )
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("PennyPath Plus. Unlock everything, try it free.")
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
