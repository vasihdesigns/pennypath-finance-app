//
//  PennyPathSchema.swift
//  PennyPath
//
//  The versioned SwiftData schema and its migration plan. Everything the app
//  persists is described here under a version number so future releases can
//  change the shape of the data WITHOUT wiping what's already on a user's
//  device. Because all data lives on-device, a careless model change is the one
//  thing that can break the app for existing users on update — this is the
//  safety net that prevents that.
//
//  HOW TO SHIP A SCHEMA CHANGE SAFELY (e.g. add a field to Account in v2):
//    1. Add a new `PennyPathSchemaV2` describing the new shape. For simple
//       additive changes it can reuse the current top-level model types; for
//       changes that must coexist with the old shape during migration, copy the
//       affected models into the enum as nested types.
//    2. Append `PennyPathSchemaV2.self` to `schemas` below (newest LAST).
//    3. Add a `MigrationStage` for V1 -> V2:
//         - `.lightweight(...)` when SwiftData can infer it (added/optional
//           fields, renames it can map) — no data-transform code needed.
//         - `.custom(...)` when you must transform existing rows during upgrade.
//    4. Point `AppStore`'s schema/version at the newest version.
//
//  Never edit an already-shipped versioned schema in place — always add a new
//  one. The shipped versions are the contract with data already on devices.
//

import Foundation
import SwiftData

/// The shape of the data shipped in PennyPath 1.0 — the baseline every future
/// migration starts from. The model list here must match `AppStore.schema`.
enum PennyPathSchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Account.self, Expense.self, Goal.self, CategoryBudget.self,
         NetWorthSnapshot.self, Holding.self, UpcomingPayment.self]
    }
}

/// Drives SwiftData's migration from an older on-disk store up to the current
/// schema. Today there is only one version, so `stages` is empty and existing
/// stores open unchanged. Add a `MigrationStage` here for each future version.
enum PennyPathMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [PennyPathSchemaV1.self]
    }

    static var stages: [MigrationStage] {
        []
    }
}
