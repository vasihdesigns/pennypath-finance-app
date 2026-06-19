//
//  AuroraQuestsView.swift
//  PennyPath
//
//  Aurora reskin of Goals: every goal is a "quest" — a planet whose
//  golden ring closes as you save, with a little moon riding the ring's
//  leading edge. Tapping opens the real goal detail; + New quest opens
//  the real form.
//

import SwiftUI
import SwiftData

struct AuroraQuestsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @State private var showingAdd = false
    @State private var revealed = false

    private var completedCount: Int { goals.filter(\.isComplete).count }

    private var headline: String {
        if goals.isEmpty { return "No quests yet" }
        if completedCount == goals.count { return "Every quest complete ✨" }
        let active = goals.count - completedCount
        return active == 1 ? "One quest underway" : "\(active) quests underway"
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                AuroraOverline(text: "Quests")

                if goals.isEmpty {
                    emptyCard
                } else {
                    Text(headline)
                        .font(.auroraDisplay(28))
                        .foregroundStyle(Aurora.ink)

                    VStack(spacing: 16) {
                        ForEach(goals) { goal in
                            NavigationLink {
                                GoalDetailView(goal: goal)
                            } label: {
                                AuroraQuestCard(goal: goal, revealed: revealed)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    newQuestButton
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AuroraSky())
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.9).delay(0.1)) { revealed = true }
        }
        .tint(Aurora.gold)
    }

    private var newQuestButton: some View {
        Button { showingAdd = true } label: {
            Label("New quest", systemImage: "plus")
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Aurora.gold)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 18)
                .background {
                    RoundedRectangle(cornerRadius: Aurora.cardRadius, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1.2, dash: [5, 5]))
                        .foregroundStyle(Aurora.gold.opacity(0.55))
                }
        }
        .buttonStyle(.plain)
    }

    private var emptyCard: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Something\nworth reaching for")
                .font(.auroraDisplay(28))
                .foregroundStyle(Aurora.ink)
                .lineSpacing(3)
            Text("Pick something you'd love to save for — a bike, a trip, a rainy-day fund — and watch its ring close, orbit by orbit.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(Aurora.inkSoft)
                .lineSpacing(2)
            newQuestButton
        }
    }
}

// MARK: - Quest card: a planet with a closing ring

private struct AuroraQuestCard: View {
    let goal: Goal
    var revealed: Bool

    /// The ring brightens as the quest nears completion.
    private var ringColor: Color {
        if goal.isComplete || goal.progress >= 2.0 / 3.0 { return Aurora.mint }
        if goal.progress >= 0.4 { return Aurora.gold }
        return Aurora.violet
    }

    private var shownProgress: Double {
        revealed ? max(0.02, min(1, goal.progress)) : 0.02
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
                    .stroke(Color.white.opacity(0.10), lineWidth: 5)
                Circle()
                    .trim(from: 0, to: shownProgress)
                    .stroke(ringColor, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .shadow(color: ringColor.opacity(0.6), radius: 5)

                Text(goal.emoji).font(.system(size: 26))

                // The little moon riding the leading edge of the ring.
                if !goal.isComplete {
                    Circle()
                        .fill(.white)
                        .frame(width: 8)
                        .shadow(color: ringColor, radius: 4)
                        .offset(y: -33)
                        .rotationEffect(.degrees(shownProgress * 360))
                }
            }
            .frame(width: 66, height: 66)
            .animation(.easeInOut(duration: 0.9), value: shownProgress)

            VStack(alignment: .leading, spacing: 4) {
                Text(goal.name)
                    .font(.system(.headline, design: .rounded))
                    .foregroundStyle(Aurora.ink)
                    .lineLimit(1)
                Text(subtitle)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Aurora.inkSoft)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                Text(goal.isComplete
                     ? "Quest complete 🎉"
                     : "\(percentText(goal.progress)) of the way there")
                    .font(.system(.caption, design: .rounded).weight(.bold))
                    .foregroundStyle(ringColor)
            }

            Spacer(minLength: 8)

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Aurora.inkFaint)
        }
        .auroraCard(padding: 18, glow: goal.isComplete ? Aurora.mint : nil)
    }
}
