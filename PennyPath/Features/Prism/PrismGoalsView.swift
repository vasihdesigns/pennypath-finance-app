//
//  PrismGoalsView.swift
//  PennyPath
//
//  Prism reskin of Goals: a saved-so-far summary, then each goal as a
//  hue-coded gradient card with a white progress meter. Tapping opens the
//  real goal detail; + opens the real form.
//

import SwiftUI
import SwiftData

struct PrismGoalsView: View {
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
                    ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                        NavigationLink {
                            GoalDetailView(goal: goal)
                        } label: {
                            PrismGoalCard(goal: goal, index: index)
                        }
                        .buttonStyle(.plain)
                    }
                    newGoalButton
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Prism.bg.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .tint(Prism.accent)
    }

    private var header: some View {
        HStack {
            Text("Goals")
                .font(.prismDisplay(24))
                .foregroundStyle(Prism.ink)
            Spacer()
            PrismPlusButton { showingAdd = true }
        }
    }

    private var summaryCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 3) {
                PrismOverline(text: "Saved toward goals", tint: .white.opacity(0.92))
                Text(money(totalSaved))
                    .font(.prismAmount(24, weight: .heavy))
                    .foregroundStyle(.white)
                Text("of \(money(totalTarget))")
                    .font(.caption).foregroundStyle(.white.opacity(0.85))
            }
            Spacer(minLength: 0)
            Text(percentText(totalTarget > 0 ? totalSaved / totalTarget : 0))
                .font(.prismAmount(22, weight: .bold))
                .foregroundStyle(.white)
        }
        .prismGradientCard(Prism.gradient(for: .cash), padding: 18)
    }

    private var newGoalButton: some View {
        Button { Haptics.tap(); showingAdd = true } label: {
            Label("New goal", systemImage: "plus")
                .font(.system(.subheadline).weight(.bold))
                .foregroundStyle(Prism.accent)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Prism.surface,
                            in: RoundedRectangle(cornerRadius: Prism.cardRadius, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: Prism.cardRadius, style: .continuous)
                        .strokeBorder(Prism.accent.opacity(0.5),
                                      style: StrokeStyle(lineWidth: 1.4, dash: [6, 5]))
                )
        }
        .buttonStyle(.plain)
    }

    private var emptyCard: some View {
        VStack(spacing: 16) {
            Image(systemName: "flag.fill")
                .font(.system(size: 38)).foregroundStyle(Prism.accent)
            Text("Set something to save for")
                .font(.prismDisplay(21)).foregroundStyle(Prism.ink)
            Text("A trip, a new device, a rainy-day fund — pick a target and watch the meter fill.")
                .font(.subheadline).foregroundStyle(Prism.inkSoft)
                .multilineTextAlignment(.center)
            PrismPrimaryButton(title: "Create a goal", systemImage: "plus") { showingAdd = true }
        }
        .frame(maxWidth: .infinity)
        .prismSurfaceCard(padding: 26)
        .padding(.top, 20)
    }
}

// MARK: - Goal card (gradient box)

private struct PrismGoalCard: View {
    let goal: Goal
    let index: Int

    private var subtitle: String {
        var line = "\(money(goal.savedAmount)) of \(money(goal.targetAmount))"
        if let date = goal.targetDate {
            line += " · by \(date.formatted(.dateTime.month(.abbreviated)))"
        }
        return line
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Text(goal.emoji)
                Text(goal.name)
                    .font(.system(.headline)).foregroundStyle(.white).lineLimit(1)
                Spacer(minLength: 8)
                Text(goal.isComplete ? "Done" : percentText(goal.progress))
                    .font(.prismAmount(14, weight: .bold))
                    .foregroundStyle(.white)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(.white.opacity(0.25))
                    Capsule()
                        .fill(.white)
                        .frame(width: max(6, geo.size.width * min(1, max(0, goal.progress))))
                }
            }
            .frame(height: 7)
            Text(subtitle)
                .font(.caption).foregroundStyle(.white.opacity(0.85))
                .lineLimit(1).minimumScaleFactor(0.8)
        }
        .prismGradientCard(Prism.chartGradient(index), padding: 16)
    }
}
