//
//  ClarityGoalsView.swift
//  PennyPath
//
//  Clarity's Goals screen: each goal is a single hairline entry — name,
//  thin meter, and the one line that matters: what to set aside each
//  month to make the date. Tapping opens the real goal detail with
//  contributions; the form is the real one too.
//

import SwiftUI
import SwiftData

struct ClarityGoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var showingAdd = false

    private var activeCount: Int { goals.filter { !$0.isComplete }.count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header

                if goals.isEmpty {
                    emptyState
                } else {
                    VStack(alignment: .leading, spacing: 0) {
                        ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                ClarityGoalRow(goal: goal)
                            }
                            .buttonStyle(.plain)
                            if index < goals.count - 1 { ClarityRule() }
                        }
                    }
                    ClarityGhostButton(title: "New goal", systemImage: "plus",
                                       tint: Clarity.cobalt) {
                        showingAdd = true
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Clarity.paper)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .tint(Clarity.cobalt)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            ClarityOverline(text: "Goals")
            if !goals.isEmpty {
                Text(activeCount == 0
                     ? "Everything reached."
                     : (activeCount == 1 ? "One thing in progress."
                                         : "\(activeCount) things in progress."))
                    .font(.clarityDisplay(26))
                    .foregroundStyle(Clarity.ink)
            }
        }
    }

    private var emptyState: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Name what\nyou're saving for.")
                .font(.clarityDisplay(26))
                .foregroundStyle(Clarity.ink)
                .lineSpacing(3)
            Text("A bike, a trip, a quieter mind. Give it a number and a date, and Clarity works out the monthly pace.")
                .font(.callout)
                .foregroundStyle(Clarity.inkSoft)
                .lineSpacing(3)
            ClarityButton(title: "Set a goal") { showingAdd = true }
                .padding(.top, 6)
        }
        .padding(.top, 16)
    }
}

// MARK: - One goal, one entry

private struct ClarityGoalRow: View {
    let goal: Goal

    /// The single most useful line for this goal right now.
    private var paceLine: String {
        if goal.isComplete { return "Reached — well done." }
        if let monthly = goal.suggestedMonthly, let date = goal.targetDate {
            return "\(money(monthly)) a month makes it by \(date.formatted(.dateTime.month(.wide).year()))"
        }
        return "\(money(goal.remaining)) to go"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(goal.emoji).font(.subheadline)
                Text(goal.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Clarity.ink)
                    .lineLimit(1)
                Spacer(minLength: 12)
                Text("\(money(goal.savedAmount)) / \(money(goal.targetAmount))")
                    .font(.clarityAmount(14))
                    .foregroundStyle(Clarity.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            ClarityMeter(value: goal.progress,
                         tint: goal.isComplete ? Clarity.good : Clarity.cobalt)
            HStack {
                Text(paceLine)
                    .font(.caption)
                    .foregroundStyle(goal.isComplete ? Clarity.good : Clarity.inkFaint)
                Spacer()
                Image(systemName: "arrow.right")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(Clarity.inkFaint)
            }
        }
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }
}
