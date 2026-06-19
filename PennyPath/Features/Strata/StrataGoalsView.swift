//
//  StrataGoalsView.swift
//  PennyPath
//
//  Strata reskin of Goals: each goal a clean white card with a colored
//  proportion edge and a thin progress meter. Tapping opens the real goal
//  detail; + opens the real form.
//

import SwiftUI
import SwiftData

struct StrataGoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var showingAdd = false

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                header

                if goals.isEmpty {
                    emptyCard
                } else {
                    summaryCard
                    ForEach(goals) { goal in
                        NavigationLink {
                            GoalDetailView(goal: goal)
                        } label: {
                            StrataGoalCard(goal: goal)
                        }
                        .buttonStyle(.plain)
                    }
                    newGoalButton
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(Strata.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .tint(Strata.bg)
    }

    private var header: some View {
        HStack {
            Text("Goals")
                .font(.strataDisplay(22))
                .foregroundStyle(Strata.onBrand)
            Spacer()
            StrataPlusButton { showingAdd = true }
        }
    }

    private var summaryCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                StrataOverline(text: "Saved toward goals", tint: Strata.inkSoft)
                Text(money(totalSaved))
                    .font(.strataAmount(24, weight: .heavy))
                    .foregroundStyle(Strata.ink)
                Text("of \(money(totalTarget))")
                    .font(.caption).foregroundStyle(Strata.inkSoft)
            }
            Spacer(minLength: 0)
            Text(percentText(totalTarget > 0 ? totalSaved / totalTarget : 0))
                .font(.strataAmount(22, weight: .bold))
                .foregroundStyle(Strata.bg)
        }
        .strataCard(padding: 18)
    }

    private var newGoalButton: some View {
        Button { showingAdd = true } label: {
            Label("New goal", systemImage: "plus")
                .font(.system(.subheadline).weight(.bold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(.white.opacity(0.16),
                            in: RoundedRectangle(cornerRadius: Strata.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Strata.cardRadius, style: .continuous)
                        .strokeBorder(.white.opacity(0.5), style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.fill")
                .font(.system(size: 38)).foregroundStyle(Strata.bg)
            Text("Set something to save for")
                .font(.strataDisplay(21)).foregroundStyle(Strata.ink)
            Text("A trip, a new device, a rainy-day fund — pick a target and watch the meter fill.")
                .font(.subheadline).foregroundStyle(Strata.inkSoft)
                .multilineTextAlignment(.center)
            StrataPrimaryButton(title: "Create a goal", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .strataCard(padding: 26)
        .padding(.top, 20)
    }
}

// MARK: - Goal card

private struct StrataGoalCard: View {
    let goal: Goal

    private var subtitle: String {
        var line = "\(money(goal.savedAmount)) of \(money(goal.targetAmount))"
        if let date = goal.targetDate {
            line += " · by \(date.formatted(.dateTime.month(.abbreviated)))"
        }
        return line
    }

    var body: some View {
        HStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 3)
                .fill(goal.isComplete ? Strata.cash : Strata.bg)
                .frame(width: 5, height: 46)
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(goal.emoji)
                    Text(goal.name)
                        .font(.system(.headline)).foregroundStyle(Strata.ink).lineLimit(1)
                    Spacer(minLength: 8)
                    Text(goal.isComplete ? "Done" : percentText(goal.progress))
                        .font(.strataAmount(14, weight: .bold))
                        .foregroundStyle(goal.isComplete ? Strata.cash : Strata.bg)
                }
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule().fill(Strata.well)
                        Capsule()
                            .fill(goal.isComplete ? Strata.cash : Strata.bg)
                            .frame(width: max(6, geo.size.width * min(1, max(0, goal.progress))))
                    }
                }
                .frame(height: 7)
                Text(subtitle)
                    .font(.caption).foregroundStyle(Strata.inkSoft)
                    .lineLimit(1).minimumScaleFactor(0.8)
            }
        }
        .strataCard(padding: 16)
    }
}
