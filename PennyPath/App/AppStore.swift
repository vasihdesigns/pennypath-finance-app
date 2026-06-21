//
//  AppStore.swift
//  PennyPath
//
//  Owns the active SwiftData container and the Demo Mode switch.
//
//  Demo Mode is non-destructive: turning it ON swaps the whole app onto a
//  throwaway in-memory store filled with a rich example world, while your real
//  data stays safe on disk. Turning it OFF rebuilds the on-disk store and your
//  real numbers come right back.
//

import SwiftUI
import SwiftData
import OSLog

@Observable
final class AppStore {
    // Built from the versioned schema so on-disk stores carry a version stamp
    // and `PennyPathMigrationPlan` can upgrade them on future releases. See
    // PennyPathSchema.swift for how to add a version safely.
    private static let schema = Schema(versionedSchema: PennyPathSchemaV1.self)
    private static let logger = Logger(subsystem: "com.vasih.PennyPath", category: "AppStore")

    /// How the active container relates to the user's on-disk data.
    enum StoreHealth {
        /// The on-disk store opened normally.
        case healthy
        /// The on-disk store couldn't be read. Its files were set aside (kept
        /// on device) and a fresh persistent store created — changes save
        /// again, but past data lives only in the set-aside files.
        case resetAfterFailure
        /// Even a fresh on-disk store couldn't be created; running on a
        /// throwaway in-memory store — changes will NOT survive a relaunch.
        /// The UI must warn the user when this is set.
        case inMemoryFallback
    }

    /// The container currently driving the UI (real on first launch, demo when toggled).
    private(set) var container: ModelContainer

    private(set) var storeHealth: StoreHealth = .healthy

    /// True when nothing entered now will survive a relaunch.
    var isFallbackStore: Bool { storeHealth == .inMemoryFallback }

    /// User-defaults key for the iCloud Sync toggle, shared with Settings.
    static let iCloudSyncKey = "iCloudSyncEnabled"

    /// Whether the real on-disk store mirrors to the user's private iCloud
    /// (CloudKit). Flipping it rebuilds the container onto / off of CloudKit.
    /// Off by default until the iCloud capability is provisioned in Xcode.
    var iCloudSyncEnabled: Bool = UserDefaults.standard.bool(forKey: AppStore.iCloudSyncKey) {
        didSet {
            guard oldValue != iCloudSyncEnabled else { return }
            UserDefaults.standard.set(iCloudSyncEnabled, forKey: Self.iCloudSyncKey)
            if !isDemo {
                (container, storeHealth) = Self.makeContainer(isDemo: false, useCloudKit: iCloudSyncEnabled)
            }
        }
    }

    /// Flip this to swap the whole app between real data and the demo world.
    var isDemo: Bool = false {
        didSet {
            guard oldValue != isDemo else { return }
            // Demo always runs local/in-memory; real data honours the iCloud setting.
            (container, storeHealth) = Self.makeContainer(isDemo: isDemo,
                                                          useCloudKit: !isDemo && iCloudSyncEnabled)
        }
    }

    init() {
        let useCloudKit = UserDefaults.standard.bool(forKey: AppStore.iCloudSyncKey)
        (container, storeHealth) = Self.makeContainer(isDemo: false, useCloudKit: useCloudKit)
    }

    /// `storeURL` exists so tests can point the on-disk store at a temp file;
    /// the app always passes nil and uses the default location. `useCloudKit`
    /// mirrors the real store to the user's private CloudKit database.
    static func makeContainer(isDemo: Bool, useCloudKit: Bool = false, storeURL: URL? = nil) -> (ModelContainer, StoreHealth) {
        func config(cloudKit: Bool) -> ModelConfiguration {
            // Demo and test stores must NEVER touch CloudKit. With the iCloud
            // entitlement present, leaving `cloudKitDatabase` unspecified defaults
            // it to `.automatic`, and SwiftData then tries to mirror the throwaway
            // in-memory store to CloudKit — which aborts with an uncaught
            // "No eligible connection available" on a real, iCloud-signed-in
            // device (it's inert on the Simulator, which has no CloudKit). Pin
            // these to `.none` so the demo world stays purely local.
            if isDemo { return ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none) }
            if let storeURL { return ModelConfiguration(schema: schema, url: storeURL, cloudKitDatabase: .none) }
            return ModelConfiguration(schema: schema, cloudKitDatabase: cloudKit ? .automatic : .none)
        }
        let wantsCloud = useCloudKit && !isDemo && storeURL == nil
        do {
            return (try openAndSeed(config(cloudKit: wantsCloud), isDemo: isDemo), .healthy)
        } catch {
            logger.error("Store failed to open: \(error, privacy: .public)")
            // If iCloud was requested but unavailable (e.g. not provisioned, or
            // signed out of iCloud), fall back to a plain local store rather than
            // alarming the user — their data still saves on device.
            if wantsCloud, let local = try? openAndSeed(config(cloudKit: false), isDemo: false) {
                logger.notice("iCloud unavailable — using local store.")
                return (local, .healthy)
            }
            // A real store that won't open is usually a corrupt or
            // incompatible file. Set it aside (kept on device) and start a
            // fresh persistent store, rather than dooming every change to an
            // in-memory fallback on this and all future launches.
            let localConfig = config(cloudKit: false)
            if !isDemo, setAsideUnreadableStore(at: localConfig.url),
               let fresh = try? openAndSeed(localConfig, isDemo: false) {
                return (fresh, .resetAfterFailure)
            }
            // Last resort: an empty in-memory store so the app still launches.
            // `.none` for the same reason as above — never CloudKit-mirror it.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true, cloudKitDatabase: .none)
            return (try! ModelContainer(for: schema, configurations: [fallback]),
                    isDemo ? .healthy : .inMemoryFallback)
        }
    }

    private static func openAndSeed(_ config: ModelConfiguration, isDemo: Bool) throws -> ModelContainer {
        // The migration plan upgrades older on-disk stores to the current schema
        // before the app reads them. Demo runs on a fresh in-memory store, so it
        // never needs migrating, but passing the plan is harmless either way.
        let container = try ModelContainer(for: schema, migrationPlan: PennyPathMigrationPlan.self, configurations: [config])
        // Seed through a throwaway context so this stays off the main actor.
        let context = ModelContext(container)
        if isDemo {
            DemoData.fill(context)
        } else {
            migrateLegacyExpenseCategories(in: context)
            SampleData.seedIfNeeded(in: context)
        }
        if context.hasChanges { try? context.save() }
        return container
    }

    /// Renames expense and budget categories saved under older taxonomies to the
    /// current names (Bills → Subscriptions, Home → Rent, and the short-lived
    /// Entertainment → Fun) so older data keeps showing in the right place
    /// instead of quietly falling back to "Other". Idempotent — a no-op once
    /// every record is already on the current names.
    private static func migrateLegacyExpenseCategories(in context: ModelContext) {
        let remap = ["bills": "subscriptions", "home": "rent", "entertainment": "fun"]
        if let expenses = try? context.fetch(FetchDescriptor<Expense>()) {
            for expense in expenses {
                if let new = remap[expense.categoryRaw] { expense.categoryRaw = new }
            }
        }
        if let budgets = try? context.fetch(FetchDescriptor<CategoryBudget>()) {
            for budget in budgets {
                if let new = remap[budget.categoryRaw] { budget.categoryRaw = new }
            }
        }
        // UpcomingPayment once carried its own category taxonomy; subscriptions
        // and future payments now share ExpenseCategory with logged expenses.
        // Remap the old codes that don't already name an ExpenseCategory
        // (`health`/`other` are valid in both and pass through untouched).
        let paymentRemap = ["productivity": "subscriptions", "entertainment": "fun",
                            "investmentFinance": "other", "personal": "other",
                            "business": "subscriptions", "education": "subscriptions"]
        if let payments = try? context.fetch(FetchDescriptor<UpcomingPayment>()) {
            for payment in payments {
                if let new = paymentRemap[payment.categoryRaw] { payment.categoryRaw = new }
            }
        }
    }

    /// Renames the store files (.store plus SQLite's -wal/-shm siblings) so a
    /// fresh store can be created in their place. The renamed files stay on
    /// device, so the data is recoverable. Returns false if nothing moved.
    private static func setAsideUnreadableStore(at url: URL) -> Bool {
        let fm = FileManager.default
        let stamp = Int(Date.now.timeIntervalSince1970)
        var movedAny = false
        for suffix in ["", "-wal", "-shm"] {
            let source = URL(fileURLWithPath: url.path + suffix)
            guard fm.fileExists(atPath: source.path) else { continue }
            let target = URL(fileURLWithPath: url.path + suffix + ".unreadable-\(stamp)")
            do {
                try fm.moveItem(at: source, to: target)
                movedAny = true
            } catch {
                logger.error("Couldn't set aside \(source.lastPathComponent, privacy: .public): \(error, privacy: .public)")
            }
        }
        return movedAny
    }
}
