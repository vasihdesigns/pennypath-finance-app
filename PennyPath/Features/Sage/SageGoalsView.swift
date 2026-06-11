//
//  SageGoalsView.swift
//  PennyPath
//
//  Sage reskin of Goals: "Three things you're building toward" — each
//  goal as a quiet card with a progress ring whose color warms up as you
//  get closer. Tapping opens the real goal detail; + New goal opens the
//  real form.
//

import SwiftUI
import SwiftData

struct SageGoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var showingAdd = false

    private static let countWords = [
        "One", "Two", "Three", "Four", "Five", "Six", "Seven", "Eight", "Nine", "Ten"
    ]

    private var heading: String {
        let count = goals.count
        let word = count <= 10 ? Self.countWords[count - 1] : "\(count)"
        return count == 1
            ? "One thing\nyou're building toward"
            : "\(word) things\nyou're building toward"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                SageOverline(text: "Goals")

                if goals.isEmpty {
                    emptyCard
                } else {
                    Text(heading)
                        .font(.sageDisplay(28))
                        .foregroundStyle(Sage.ink)
                        .lineSpacing(3)

                    VStack(spacing: 16) {
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                SageGoalCard(goal: goal)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    newGoalButton
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Sage.bg)
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .tint(Sage.green)
    }

    private var newGoalButton: some View {
        Button { showingAdd = true } label: {
            Text("+ New goal")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Sage.green)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: Sage.cardRadius, style: .continuous)
                        .stroke(style: StrokeStyle(lineWidth: 1.2, dash: [5, 5]))
                        .foregroundStyle(Sage.green.opacity(0.5))
                }
        }
        .buttonStyle(.plain)
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Something\nworth building toward")
                .font(.sageDisplay(28))
                .foregroundStyle(Sage.ink)
                .lineSpacing(3)
            Text("Pick something you'd love to save for — a bike, a trip, a rainy-day fund — and watch it fill up.")
                .font(.subheadline)
                .foregroundStyle(Sage.inkSoft)
            newGoalButton
        }
    }
}

// MARK: - Goal card with a progress ring

private struct SageGoalCard: View {
    let goal: Goal

    /// The ring warms with progress: terracotta early, slate midway,
    /// green on the home stretch.
    private var ringColor: Color {
        if goal.isComplete || goal.progress >= 2.0 / 3.0 { return Sage.green }
        if goal.progress >= 0.4 { return Sage.slate }
        return Sage.terracotta
    }

    private var subtitle: String {
        var line = "\(money(goal.savedAmount)) of \(money(goal.targetAmount))"
        if let date = goal.targetDate {
            line += " · by \(date.formatted(.dateTime.month(.abbreviated)))"
        }
        return line
    }

    var body: some View {
        HStack(spacing: 18) {
            ZStack {
                Circle()
                    .stroke(Sage.well, lineWidth: 5)
                Circle()
                    .trim(from: 0, to: max(0.02, min(1, goal.progress)))
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(goal.isComplete ? "🎉" : percentText(goal.progress))
                    .font(.sageAmount(14, weight: .medium))
                    .foregroundStyle(Sage.ink)
            }
            .frame(width: 62, height: 62)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.headline)
                    .foregroundStyle(Sage.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.footnote)
                    .foregroundStyle(Sage.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(Sage.inkFaint)
        }
        .sageCard(padding: 20)
    }
}
