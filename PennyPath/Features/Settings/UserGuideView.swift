//
//  UserGuideView.swift
//  PennyPath
//
//  Settings → User Guide. A friendly, plain-language walkthrough of how PennyPath
//  works, grouped by topic with tap-to-expand answers. Pure text and SF Symbols —
//  no data access — so it reads the same in Demo Mode or with a brand-new store.
//  Reached from SettingsView's Help & legal section.
//

import SwiftUI

struct UserGuideView: View {
    // Expanded by default so the first thing the reader sees is an answer, not a
    // wall of closed rows. Tapping any other topic still works the usual way.
    @State private var expanded: UUID?

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Welcome to PennyPath")
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                    Text("A calm place for your whole financial life. Here's how everything fits together — tap any question to see more.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.inkSecondary)
                }
                .padding(.vertical, 4)
            }

            ForEach(Self.topics) { topic in
                Section {
                    ForEach(topic.entries) { entry in
                        GuideRow(entry: entry,
                                 isExpanded: Binding(
                                    get: { expanded == entry.id },
                                    set: { expanded = $0 ? entry.id : nil }))
                    }
                } header: {
                    Label(topic.title, systemImage: topic.symbol)
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(Theme.inkSecondary)
                        .textCase(nil)
                }
            }
        }
        .navigationTitle("User Guide")
        .navigationBarTitleDisplayMode(.inline)
        .tint(Theme.ink)
    }
}

// MARK: - One expandable question

private struct GuideRow: View {
    let entry: GuideEntry
    @Binding var isExpanded: Bool

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded.animation(.easeInOut(duration: 0.2))) {
            Text(LocalizedStringKey(entry.answer))
                .font(.callout)
                .foregroundStyle(Theme.inkSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)
                .padding(.bottom, 2)
        } label: {
            Text(entry.question)
                .font(.body.weight(.medium))
                .foregroundStyle(Theme.ink)
        }
    }
}

// MARK: - Content model

private struct GuideEntry: Identifiable {
    let id = UUID()
    let question: String
    let answer: String
}

private struct GuideTopic: Identifiable {
    let id = UUID()
    let title: String
    let symbol: String
    let entries: [GuideEntry]
}

// MARK: - The guide

private extension UserGuideView {
    static let topics: [GuideTopic] = [
        GuideTopic(title: "Getting around", symbol: "square.grid.2x2", entries: [
            GuideEntry(
                question: "What are the four tabs?",
                answer: "**Net Worth** is your home base — everything you own and owe. **Expenses** is where you log spending and watch your budgets. **Goals** tracks what you're saving toward. **Insights** offers quiet tips drawn from your own numbers."),
            GuideEntry(
                question: "How do I add something?",
                answer: "Look for the **+** button on each tab. One add screen handles it all — an account, an investment, an expense, an upcoming payment, or a goal. Flip the **Repeats** switch to turn a one-off expense into a recurring payment or subscription."),
            GuideEntry(
                question: "How do I edit or remove an item?",
                answer: "Tap any card or row to open its editor, change the details, and save. To hide an account or goal without losing its history, **archive** it from its editor — you'll find archived items under Settings → Archived."),
        ]),

        GuideTopic(title: "Net Worth", symbol: "chart.line.uptrend.xyaxis", entries: [
            GuideEntry(
                question: "What's the one big number?",
                answer: "It's your **net worth** — everything you own (cash, investments, property) minus everything you owe (cards, loans). It updates live as you add accounts and as investment prices refresh."),
            GuideEntry(
                question: "Why is each account a different colour?",
                answer: "Cards are grouped by kind — cash, investments, property, and debts each get their own jewel tone — so you can read your whole picture at a glance. The pie icon by Settings opens a full-screen breakdown of how it all splits."),
            GuideEntry(
                question: "Can I track accounts in another currency?",
                answer: "Yes. Each account can hold its own currency and is converted to your main currency using live exchange rates. Change your main currency anytime in **Settings → Currency**."),
        ]),

        GuideTopic(title: "Expenses & budgets", symbol: "creditcard", entries: [
            GuideEntry(
                question: "How do budgets work?",
                answer: "Each category gets a monthly limit. As you spend, its bar **fills and changes colour** — calm when you're on track, warmer as you near the limit — so nothing sneaks up on you."),
            GuideEntry(
                question: "How do I log spending?",
                answer: "Tap **+** on the Expenses tab and enter the amount, category, and an optional note. Your budgets update instantly."),
            GuideEntry(
                question: "What about subscriptions and bills?",
                answer: "Add them as **upcoming payments** with a repeat cycle. PennyPath remembers when each is due and can even look up an app's name and icon when you type a subscription."),
        ]),

        GuideTopic(title: "Goals", symbol: "flag", entries: [
            GuideEntry(
                question: "How do I save toward something?",
                answer: "Create a goal with a target amount, then add money to it over time. Its dial fills as you get closer, and you'll see exactly how much is left to go."),
            GuideEntry(
                question: "What are milestones?",
                answer: "The **Milestones** segment on the Goals tab is a net-worth ladder — from your first $1,000 up to bigger rungs. Each one lights up as your net worth climbs past it."),
        ]),

        GuideTopic(title: "Insights", symbol: "sparkles", entries: [
            GuideEntry(
                question: "Where do tips come from?",
                answer: "Insights are generated **entirely on your device** from the numbers you've already entered — like spotting that you spent less this month. Nothing about your finances is sent anywhere to produce them."),
        ]),

        GuideTopic(title: "Your data & privacy", symbol: "lock.shield", entries: [
            GuideEntry(
                question: "Where is my data stored?",
                answer: "On your iPhone. There's **no account and no sign-up**. If you turn on **iCloud Sync** (Settings → Backup & sync), a private copy is kept in *your* iCloud and synced across your devices — it never passes through our servers."),
            GuideEntry(
                question: "Do you collect or track anything?",
                answer: "No analytics, no tracking, no selling data. The only network use is fetching **public** market prices and exchange rates for investments and currencies you add, and looking up an app's name and icon for subscriptions."),
            GuideEntry(
                question: "How do I back up or move my data?",
                answer: "Use **Export data (.json)** in Settings to save a copy you can keep anywhere, and **Import data (.json)** to restore it — handy when moving to a new phone. Importing replaces what's currently in the app."),
            GuideEntry(
                question: "Can I lock the app?",
                answer: "Turn on **Require Face ID / Touch ID** in Settings → Privacy & Security. PennyPath then hides your balances in the app switcher and opens only with Face ID, Touch ID, or your passcode."),
        ]),

        GuideTopic(title: "Handy extras", symbol: "wand.and.stars", entries: [
            GuideEntry(
                question: "How can I add an expense faster?",
                answer: "The built-in **Add Expense** shortcut works with Siri, the Home Screen, and Back Tap. Set it up under Settings → Quick add shortcut."),
            GuideEntry(
                question: "What is Demo Mode?",
                answer: "It fills the app with a rich example world so you can explore or show it off. Your real data is kept safe and comes right back when you turn it off."),
            GuideEntry(
                question: "Can I see the welcome tour again?",
                answer: "Yes — enable **Developer Mode** (tap the version number five times in Settings → About), then choose **Replay onboarding**."),
        ]),
    ]
}
