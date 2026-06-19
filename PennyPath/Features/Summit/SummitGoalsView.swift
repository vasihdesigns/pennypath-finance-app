//
//  SummitGoalsView.swift
//  PennyPath
//
//  Summit's Goals screen, with two segments:
//    • Goals — what you're saving toward (pots you create and fund).
//    • Milestones — the automatic net-worth climb ($1K → $1M+).
//  They live side by side so the difference is clear: goals are chosen and
//  funded; milestones are reached as your net worth grows. The Net Worth tab
//  keeps a compact "next milestone" chip that deep-links into the Milestones
//  segment here.
//

import SwiftUI
import SwiftData

/// Which segment of the Goals tab is showing. Bound from the root so the Net
/// Worth chip can open straight onto Milestones.
enum SummitGoalsSegment: String, CaseIterable {
    case goals = "Goals"
    case milestones = "Milestones"
}

struct SummitGoalsView: View {
    @Binding var segment: SummitGoalsSegment

    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @Query private var accounts: [Account]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"
    @AppStorage("summitHideAmounts") private var hideAmounts = false

    @State private var showingAdd = false
    @State private var showingSettings = false

    // Goals
    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var completedCount: Int { goals.filter(\.isComplete).count }

    // Net worth (drives milestones) — same maths as the Net Worth screen.
    private var netWorth: Double {
        accounts.reduce(0) { $0 + $1.signedBalance }
    }

    private func mask(_ value: Double) -> String {
        hideAmounts ? "••••••" : money(value, code: currencyCode)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SummitSegmented(items: SummitGoalsSegment.allCases, title: \.rawValue, selection: $segment)
                switch segment {
                case .goals:      goalsContent
                case .milestones: milestonesContent
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 4)
            .padding(.bottom, 28)
        }
        .background(Summit.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .safeAreaInset(edge: .top) {
            SummitTopBar(title: "Goals",
                         privacy: $hideAmounts,
                         onAdd: segment == .goals ? { showingAdd = true } : nil,
                         onSettings: { showingSettings = true })
                .padding(.horizontal, 20)
                .padding(.top, 4)
                .padding(.bottom, 10)
                .background(Summit.canvas)
        }
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .tint(Summit.accent)
    }

    // MARK: Goals segment

    @ViewBuilder
    private var goalsContent: some View {
        if goals.isEmpty {
            goalsEmpty
        } else {
            summaryCard
            ForEach(goals) { goal in
                NavigationLink {
                    GoalDetailView(goal: goal)
                } label: {
                    goalCard(goal)
                }
                .buttonStyle(.plain)
            }
            SummitAddRow(title: "New goal") { showingAdd = true }
                .padding(.top, 2)
        }
    }

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    SummitOverline(text: "Saved toward goals", tint: Summit.inkSoft)
                    Text(mask(totalSaved))
                        .font(.summitNumber(28, weight: .heavy))
                        .foregroundStyle(Summit.ink)
                    Text("of \(mask(totalTarget))")
                        .font(.summitText(13))
                        .foregroundStyle(Summit.inkFaint)
                }
                Spacer()
                Text(percentText(totalTarget > 0 ? totalSaved / totalTarget : 0))
                    .font(.summitNumber(22, weight: .bold))
                    .foregroundStyle(Summit.gold)
            }
            SummitMeter(value: totalTarget > 0 ? totalSaved / totalTarget : 0, tint: Summit.gold, height: 9)
            if completedCount > 0 {
                Text("🏆 \(completedCount) goal\(completedCount == 1 ? "" : "s") reached")
                    .font(.summitText(13, weight: .medium))
                    .foregroundStyle(Summit.gold)
            }
        }
        .summitCard(padding: 18)
    }

    private func goalCard(_ goal: Goal) -> some View {
        let tint = goal.isComplete ? Summit.accent : Summit.gold
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.system(size: 18))
                    .frame(width: 38, height: 38)
                    .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 11, style: .continuous))
                VStack(alignment: .leading, spacing: 1) {
                    Text(goal.name)
                        .font(.summitText(16, weight: .semibold))
                        .foregroundStyle(Summit.ink)
                        .lineLimit(1)
                    Text(subtitle(goal))
                        .font(.summitText(12))
                        .foregroundStyle(Summit.inkFaint)
                        .lineLimit(1)
                }
                Spacer(minLength: 8)
                if goal.isComplete {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(Summit.accent)
                } else {
                    Text(percentText(goal.progress))
                        .font(.summitNumber(15, weight: .bold))
                        .foregroundStyle(Summit.gold)
                }
            }
            SummitMeter(value: goal.progress, tint: tint, height: 8)
        }
        .summitCard(padding: 16)
    }

    private func subtitle(_ goal: Goal) -> String {
        var line = "\(mask(goal.savedAmount)) of \(mask(goal.targetAmount))"
        if let date = goal.targetDate {
            line += " · by \(date.formatted(.dateTime.month(.abbreviated).year()))"
        }
        return line
    }

    private var goalsEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Summit.gold)
            Text("Set something to save for")
                .font(.summitSerif(22, weight: .semibold))
                .foregroundStyle(Summit.ink)
            Text("A house deposit, a fund, a dream — name a target and watch the gold meter fill.")
                .font(.summitText(14))
                .foregroundStyle(Summit.inkSoft)
                .multilineTextAlignment(.center)
            SummitPrimaryButton(title: "Create a goal", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .summitCard(padding: 28)
        .padding(.top, 24)
    }

    // MARK: Milestones segment

    @ViewBuilder
    private var milestonesContent: some View {
        if accounts.isEmpty {
            milestonesEmpty
        } else {
            milestoneContextRow
            nextMilestoneCard
            HStack {
                SummitOverline(text: "The climb")
                Spacer()
                Text("\(SummitMilestones.reachedCount(netWorth)) of \(SummitMilestones.ladder.count) reached")
                    .font(.summitText(12, weight: .medium))
                    .foregroundStyle(Summit.inkFaint)
            }
            .padding(.top, 4)
            climbCard
        }
    }

    private var milestoneContextRow: some View {
        HStack {
            Text("From your net worth")
                .font(.summitText(13))
                .foregroundStyle(Summit.inkSoft)
            Spacer()
            Text(mask(netWorth))
                .font(.summitNumber(14, weight: .semibold))
                .foregroundStyle(Summit.ink)
        }
        .padding(.horizontal, 2)
    }

    @ViewBuilder
    private var nextMilestoneCard: some View {
        if let next = SummitMilestones.next(after: netWorth) {
            let progress = SummitMilestones.progress(netWorth)
            let toGo = max(0, next - netWorth)
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Next milestone")
                            .font(.summitText(13, weight: .medium))
                            .foregroundStyle(Summit.inkSoft)
                        Text(summitCompact(next))
                            .font(.summitNumber(28, weight: .heavy))
                            .foregroundStyle(Summit.ink)
                    }
                    Spacer()
                    Text(percentText(progress))
                        .font(.summitNumber(20, weight: .bold))
                        .foregroundStyle(Summit.gold)
                }
                SummitMeter(value: progress, tint: Summit.gold, height: 9)
                Text(netWorth < 0
                     ? "Clear what you owe to reach \(summitCompact(next))."
                     : "\(mask(toGo)) to go — keep climbing.")
                    .font(.summitText(13))
                    .foregroundStyle(Summit.inkSoft)
            }
            .summitCard(padding: 18)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("🏔️ Summit reached")
                    .font(.summitSerif(20, weight: .semibold))
                    .foregroundStyle(Summit.ink)
                Text("You've passed every milestone on the ladder. Remarkable.")
                    .font(.summitText(13))
                    .foregroundStyle(Summit.inkSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .summitCard(padding: 18)
        }
    }

    private var climbCard: some View {
        VStack(spacing: 0) {
            let rungs = SummitMilestones.ladder
            ForEach(Array(rungs.enumerated()), id: \.element) { index, rung in
                rungRow(rung)
                if index < rungs.count - 1 {
                    Summit.hairline.frame(height: 1).padding(.leading, 44)
                }
            }
        }
        .summitCard(padding: 8)
    }

    private func rungRow(_ rung: Double) -> some View {
        let reached = netWorth >= rung
        let isNext = SummitMilestones.next(after: netWorth) == rung
        return HStack(spacing: 12) {
            Image(systemName: reached ? "checkmark.circle.fill" : (isNext ? "flag.fill" : "circle"))
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(reached ? Summit.gold : (isNext ? Summit.accent : Summit.inkFaint))
                .frame(width: 24)
            Text(summitCompact(rung))
                .font(.summitNumber(16, weight: .semibold))
                .foregroundStyle(reached || isNext ? Summit.ink : Summit.inkFaint)
            Spacer(minLength: 8)
            Text(reached ? "Reached" : (isNext ? "\(mask(max(0, rung - netWorth))) to go" : ""))
                .font(.summitText(12, weight: .medium))
                .foregroundStyle(reached ? Summit.gold : Summit.inkSoft)
        }
        .padding(.vertical, 11)
        .padding(.horizontal, 8)
        .background {
            if isNext {
                RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Summit.accentSoft)
            }
        }
    }

    private var milestonesEmpty: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Summit.gold)
            Text("Your climb starts on Net Worth")
                .font(.summitSerif(22, weight: .semibold))
                .foregroundStyle(Summit.ink)
            Text("Add what you own and owe, and milestones from your first \(summitCompact(1_000)) to \(summitCompact(1_000_000)) and beyond will appear here.")
                .font(.summitText(14))
                .foregroundStyle(Summit.inkSoft)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .summitCard(padding: 28)
        .padding(.top, 24)
    }
}
