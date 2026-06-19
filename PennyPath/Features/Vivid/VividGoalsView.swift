//
//  VividGoalsView.swift
//  PennyPath
//
//  Vivid reskin of Goals: a big donut hero showing everything you've saved
//  across your goals, then each goal as a card with its own progress ring.
//  Tapping a card opens the real goal detail; + New goal opens the real form.
//

import SwiftUI
import SwiftData

struct VividGoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var showingAdd = false

    private static let countWords = [
        "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"
    ]

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var overallProgress: Double {
        totalTarget > 0 ? min(1, totalSaved / totalTarget) : 0
    }

    private var heading: String {
        let count = goals.count
        let word = count <= 10 ? Self.countWords[count - 1] : "\(count)"
        return count == 1
            ? "One thing you're building toward"
            : "\(word) things you're building toward"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                header

                if goals.isEmpty {
                    emptyCard
                } else {
                    donutHero
                    Text(heading)
                        .font(.vividDisplay(20))
                        .foregroundStyle(Vivid.ink)
                    VStack(spacing: 14) {
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                VividGoalCard(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    newGoalButton
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Vivid.bg)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .tint(Vivid.violet)
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VividOverline(text: "Goals")
            Spacer()
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Vivid.violet)
                    .frame(width: 38, height: 38)
                    .background(Vivid.violet.opacity(0.12), in: Circle())
            }
            .accessibilityLabel("New goal")
        }
    }

    // MARK: Donut hero — total saved across every goal

    private var donutHero: some View {
        VividDonut(progress: overallProgress, lineWidth: 24) {
            VStack(spacing: 3) {
                VividOverline(text: "Saved")
                VividAmount(value: totalSaved, size: 32)
                Text("of \(money(totalTarget))")
                    .font(.system(.footnote, design: .rounded).weight(.medium))
                    .foregroundStyle(Vivid.inkSoft)
            }
        }
        .frame(width: 220, height: 220)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .accessibilityElement()
        .accessibilityLabel("Saved across all goals")
        .accessibilityValue("\(money(totalSaved)) of \(money(totalTarget)), \(percentText(overallProgress))")
    }

    private var newGoalButton: some View {
        Button { showingAdd = true } label: {
            Label("New goal", systemImage: "plus")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Vivid.violet)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: Vivid.cardRadius, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
                        .foregroundStyle(Vivid.violet.opacity(0.5))
                }
        }
        .buttonStyle(.plain)
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Text("🎯").font(.system(size: 44))
            Text("Something worth\nbuilding toward")
                .font(.vividDisplay(24))
                .foregroundStyle(Vivid.ink)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
            Text("Pick something you'd love to save for — a trip, a new bike, a rainy-day fund — and watch the ring fill up.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Vivid.inkSoft)
                .multilineTextAlignment(.center)
            VividPrimaryButton(title: "Create a goal", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .vividCard(padding: 28)
        .padding(.top, 24)
    }
}

// MARK: - Goal card with a progress ring

private struct VividGoalCard: View {
    let goal: Goal

    private var subtitle: String {
        var line = "\(money(goal.savedAmount)) of \(money(goal.targetAmount))"
        if let date = goal.targetDate {
            line += " · by \(date.formatted(.dateTime.month(.abbreviated)))"
        }
        return line
    }

    var body: some View {
        HStack(spacing: 16) {
            VividDonut(progress: goal.progress, lineWidth: 6) {
                Text(goal.isComplete ? "🎉" : goal.emoji)
                    .font(.system(size: 20))
            }
            .frame(width: 58, height: 58)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Vivid.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Vivid.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Text(goal.isComplete ? "Done" : percentText(goal.progress))
                .font(.vividAmount(15, weight: .bold))
                .foregroundStyle(Vivid.violet)
        }
        .vividCard(padding: 18)
    }
}
