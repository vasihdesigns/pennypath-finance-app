//
//  Store.swift
//  PennyPath
//
//  StoreKit 2 wrapper for "PennyPath Plus". Loads the subscription products, runs
//  purchases and restores, listens for transaction updates, and exposes one
//  source of truth — `isPlus` — derived from the user's current entitlements.
//  StoreKit caches entitlements on-device, so `isPlus` is re-derived on every
//  launch and survives offline.
//
//  TO SHIP THIS (the two steps only you can do):
//    1. Create the two product IDs below as auto-renewable subscriptions in
//       App Store Connect (a single subscription group, with a 7-day intro offer
//       if you want the free trial the paywall mentions).
//    2. For local testing without App Store Connect, add a StoreKit Configuration
//       file (File → New → StoreKit Configuration File) with these same IDs and
//       select it in the Run scheme (Edit Scheme → Run → Options → StoreKit
//       Configuration). Until then `products` is empty and the paywall shows its
//       fallback prices and an "unavailable" notice on tap — never a fake success.
//
//  What `isPlus` UNLOCKS is a product decision left to you: nothing is gated yet,
//  so existing users keep every feature. Gate premium features on `Store.shared.isPlus`
//  when you've decided the free/paid split.
//

import StoreKit
import OSLog

@MainActor
@Observable
final class Store {
    static let shared = Store()

    /// Must match the products in App Store Connect (and any StoreKit test config).
    static let monthlyID = "com.vasih.PennyPath.plus.monthly"
    static let yearlyID = "com.vasih.PennyPath.plus.yearly"
    static var productIDs: [String] { [monthlyID, yearlyID] }

    private static let logger = Logger(subsystem: "com.vasih.PennyPath", category: "Store")

    /// Loaded products. Empty until `load()` succeeds (offline, or no StoreKit
    /// config/products configured during development).
    private(set) var products: [Product] = []
    /// True when the user holds an active, unrevoked Plus entitlement.
    private(set) var isPlus = false
    /// True while a purchase or restore is in flight.
    private(set) var isWorking = false

    private var updates: Task<Void, Never>?

    private init() {
        // The shared store lives for the whole app session, so the updates task
        // is never cancelled — no deinit needed (and a nonisolated deinit can't
        // touch this main-actor state anyway).
        updates = listenForTransactions()
        Task {
            await load()
            await refreshEntitlement()
        }
    }

    func product(_ id: String) -> Product? { products.first { $0.id == id } }

    /// Fetch products from the App Store (or the local StoreKit config).
    func load() async {
        do {
            // Most-expensive (yearly) first, matching the paywall's default plan.
            products = try await Product.products(for: Self.productIDs).sorted { $0.price > $1.price }
        } catch {
            Self.logger.error("Product load failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Returns true on a successful, verified purchase.
    @discardableResult
    func purchase(_ product: Product) async -> Bool {
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                guard case .verified(let transaction) = verification else { return false }
                await transaction.finish()
                await refreshEntitlement()
                return isPlus
            case .userCancelled, .pending:
                return false
            @unknown default:
                return false
            }
        } catch {
            Self.logger.error("Purchase failed: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    /// Restore prior purchases — StoreKit syncs and entitlements re-derive.
    func restore() async {
        isWorking = true
        defer { isWorking = false }
        // Qualified: the app has its own `AppStore` (the SwiftData store owner),
        // which would otherwise shadow StoreKit's.
        try? await StoreKit.AppStore.sync()
        await refreshEntitlement()
    }

    /// Recompute `isPlus` from the current, verified entitlements.
    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            guard case .verified(let transaction) = result else { continue }
            if Self.productIDs.contains(transaction.productID), transaction.revocationDate == nil {
                active = true
            }
        }
        isPlus = active
    }

    /// Keep `isPlus` live for renewals, refunds, and Ask-to-Buy approvals that
    /// land outside an active purchase flow.
    private func listenForTransactions() -> Task<Void, Never> {
        Task(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }
}
