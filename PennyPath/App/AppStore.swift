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

@Observable
final class AppStore {
    private static let schema = Schema([Account.self, Expense.self, Goal.self, CategoryBudget.self, NetWorthSnapshot.self, Holding.self])

    /// The container currently driving the UI (real on first launch, demo when toggled).
    private(set) var container: ModelContainer

    /// Flip this to swap the whole app between real data and the demo world.
    var isDemo: Bool = false {
        didSet {
            guard oldValue != isDemo else { return }
            container = Self.makeContainer(isDemo: isDemo)
        }
    }

    init() {
        container = Self.makeContainer(isDemo: false)
    }

    private static func makeContainer(isDemo: Bool) -> ModelContainer {
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: isDemo)
        do {
            let container = try ModelContainer(for: schema, configurations: [config])
            // Seed through a throwaway context so this stays off the main actor.
            let context = ModelContext(container)
            if isDemo {
                DemoData.fill(context)
            } else {
                SampleData.seedIfNeeded(in: context)
            }
            if context.hasChanges { try? context.save() }
            return container
        } catch {
            // Last resort: an empty in-memory store so the app still launches.
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            return try! ModelContainer(for: schema, configurations: [fallback])
        }
    }
}
