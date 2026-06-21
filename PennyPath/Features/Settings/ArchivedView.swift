//
//  ArchivedView.swift
//  PennyPath
//
//  Settings → Archived. A holding area for the accounts and goals the user has
//  archived: they stay out of net worth, the deck, the goal list, insights, and
//  history, but nothing is lost. From here each one can be restored in a tap, or
//  deleted for good behind a clear confirmation + disclaimer. Reached from
//  SettingsView.
//

import SwiftUI
import SwiftData

struct ArchivedView: View {
    @Environment(\.modelContext) private var context

    // Newest archive first. nil archivedAt (legacy) sorts to the bottom.
    @Query(filter: #Predicate<Account> { $0.isArchived },
           sort: \Account.archivedAt, order: .reverse) private var accounts: [Account]
    @Query(filter: #Predicate<Goal> { $0.isArchived },
           sort: \Goal.archivedAt, order: .reverse) private var goals: [Goal]

    /// The item awaiting a permanent-delete confirmation, if any.
    @State private var pendingDeleteAccount: Account?
    @State private var pendingDeleteGoal: Goal?

    private var isEmpty: Bool { accounts.isEmpty && goals.isEmpty }

    var body: some View {
        Group {
            if isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Archived")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.ink)
        .confirmationDialog("Delete this account permanently?",
                            isPresented: accountDeleteShown,
                            titleVisibility: .visible,
                            presenting: pendingDeleteAccount) { account in
            Button("Delete permanently", role: .destructive) {
                context.delete(account); pendingDeleteAccount = nil; Haptics.tap()
            }
            Button("Keep", role: .cancel) { pendingDeleteAccount = nil }
        } message: { account in
            Text("“\(account.name)” and all of its details will be erased. This can't be undone — restore it instead if you might want it back.")
        }
        .confirmationDialog("Delete this goal permanently?",
                            isPresented: goalDeleteShown,
                            titleVisibility: .visible,
                            presenting: pendingDeleteGoal) { goal in
            Button("Delete permanently", role: .destructive) {
                context.delete(goal); pendingDeleteGoal = nil; Haptics.tap()
            }
            Button("Keep", role: .cancel) { pendingDeleteGoal = nil }
        } message: { goal in
            Text("“\(goal.name)” and its progress will be erased. This can't be undone — restore it instead if you might want it back.")
        }
    }

    // MARK: List

    private var list: some View {
        List {
            if !accounts.isEmpty {
                Section("Accounts") {
                    ForEach(accounts) { accountRow($0) }
                }
            }
            if !goals.isEmpty {
                Section("Goals") {
                    ForEach(goals) { goalRow($0) }
                }
            }
            Section {
            } footer: {
                Text("Archived items are hidden from your totals, the deck, goals, and insights — but nothing is lost. Swipe a row to restore it, or to delete it for good.")
            }
        }
    }

    private func accountRow(_ account: Account) -> some View {
        archivedRow(emoji: account.category.emoji,
                    name: account.name,
                    subtitle: subtitle(account.category.title, account.archivedAt),
                    trailing: money(account.balance, code: account.displayCurrencyCode),
                    trailingTint: account.category.isAsset ? Theme.ink : Theme.red,
                    restore: { restoreAccount(account) },
                    confirmDelete: { pendingDeleteAccount = account })
    }

    private func goalRow(_ goal: Goal) -> some View {
        archivedRow(emoji: goal.emoji,
                    name: goal.name,
                    subtitle: subtitle("Goal", goal.archivedAt),
                    trailing: money(goal.targetAmount),
                    trailingTint: Theme.ink,
                    restore: { restoreGoal(goal) },
                    confirmDelete: { pendingDeleteGoal = goal })
    }

    /// One shared row for an archived account or goal.
    private func archivedRow(emoji: String, name: String, subtitle: String,
                             trailing: String, trailingTint: Color,
                             restore: @escaping () -> Void,
                             confirmDelete: @escaping () -> Void) -> some View {
        HStack(spacing: Theme.Space.md) {
            EmojiBadge(emoji: emoji, size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.body)
                    .foregroundStyle(Theme.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(Theme.inkSecondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            Text(trailing)
                .font(.callout.weight(.semibold).monospacedDigit())
                .foregroundStyle(trailingTint)
                .lineLimit(1)
        }
        .swipeActions(edge: .leading, allowsFullSwipe: true) {
            Button(action: restore) { Label("Restore", systemImage: "tray.and.arrow.up") }
                .tint(Theme.green)
        }
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive, action: confirmDelete) { Label("Delete", systemImage: "trash") }
            Button(action: restore) { Label("Restore", systemImage: "tray.and.arrow.up") }
                .tint(Theme.green)
        }
        .contextMenu {
            Button("Restore", systemImage: "tray.and.arrow.up", action: restore)
            Button("Delete permanently", systemImage: "trash", role: .destructive, action: confirmDelete)
        }
    }

    private func subtitle(_ kind: String, _ archivedAt: Date?) -> String {
        var parts = [kind]
        if let when = archivedAt {
            parts.append("archived \(when.formatted(.dateTime.month(.abbreviated).day()))")
        }
        return parts.joined(separator: " · ")
    }

    // MARK: Empty

    private var emptyState: some View {
        EmptyState(emoji: "🗂️",
                   title: "Nothing archived",
                   message: "Archive an account from the Net Worth deck or a goal from the Goals list (long-press it) to tuck it away here without losing anything.")
    }

    // MARK: Actions

    private func restoreAccount(_ account: Account) {
        Haptics.success()
        withAnimation { account.isArchived = false; account.archivedAt = nil }
    }

    private func restoreGoal(_ goal: Goal) {
        Haptics.success()
        withAnimation { goal.isArchived = false; goal.archivedAt = nil }
    }

    // Drive each confirmation dialog from its optional pending item.
    private var accountDeleteShown: Binding<Bool> {
        Binding(get: { pendingDeleteAccount != nil },
                set: { if !$0 { pendingDeleteAccount = nil } })
    }
    private var goalDeleteShown: Binding<Bool> {
        Binding(get: { pendingDeleteGoal != nil },
                set: { if !$0 { pendingDeleteGoal = nil } })
    }
}
