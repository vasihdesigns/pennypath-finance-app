//
//  MonoGoalsView.swift
//  PennyPath
//
//  Mono's Goals screen on real data: how far you are across everything you're
//  saving toward, then each goal as a card with a grey bar that fills as you
//  go. Taps open the real Goal detail; the + adds a goal with the real form.
//

import SwiftUI
import SwiftData

struct MonoGoalsView: View {
    @Query(sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var showingAdd = false
    @State private var showingSettings = false

    // A completed goal reads as the strongest, fullest tone — near-black in
    // light, near-white in dark — so a finished bar looks unmistakably done.
    private let done = Color.adaptive(light: 0x111111, dark: 0xF5F5F5)

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var overallProgress: Double { totalTarget > 0 ? min(1, totalSaved / totalTarget) : 0 }
    private var completedCount: Int { goals.filter(\.isComplete).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                MonoHeader(title: "Goals") { showingSettings = true }

                if goals.isEmpty {
                    emptyCard
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
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(Mono.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            MonoPlusButton { showingAdd = true }
                .padding(.trailing, 22)
                .padding(.bottom, 58)   // sit just above the floating tab bar
        }
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    // MARK: Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 3) {
                    Text("SAVED SO FAR")
                        .font(.system(size: 11, weight: .semibold))
                        .tracking(1)
                        .foregroundStyle(Mono.onCanvasSoft)
                    Text(money(totalSaved, code: currencyCode))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundStyle(Mono.onCanvas)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    Text("of \(money(totalTarget, code: currencyCode)) across \(goals.count) goal\(goals.count == 1 ? "" : "s")")
                        .font(.system(size: 13))
                        .foregroundStyle(Mono.onCanvasSoft)
                }
                Spacer()
                Text(percentText(overallProgress))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Mono.accentSoft)
            }
            MonoMeter(value: overallProgress, tint: Mono.accentSoft)
            if completedCount > 0 {
                Text("🏆 \(completedCount) goal\(completedCount == 1 ? "" : "s") reached")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(done)
            }
        }
        .monoPanel()
    }

    // MARK: Goal card

    private func goalCard(_ goal: Goal) -> some View {
        let tint = goal.isComplete ? done : Mono.accentSoft
        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Text(goal.emoji)
                    .font(.system(size: 18))
                    .frame(width: 40, height: 40)
                    .background(tint.opacity(0.16), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Mono.onCanvas)
                        .lineLimit(1)
                    if let date = goal.targetDate {
                        Text("by \(date.monthYear)")
                            .font(.system(size: 12))
                            .foregroundStyle(Mono.onCanvasSoft)
                    }
                }
                Spacer(minLength: 8)
                Text(goal.isComplete ? "Done 🎉" : percentText(goal.progress))
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(tint)
            }
            MonoMeter(value: goal.progress, tint: tint)
            HStack {
                Text("\(money(goal.savedAmount, code: currencyCode)) of \(money(goal.targetAmount, code: currencyCode))")
                    .font(.system(size: 12))
                    .foregroundStyle(Mono.onCanvasSoft)
                Spacer()
                if !goal.isComplete {
                    Text("\(money(goal.remaining, code: currencyCode)) to go")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Mono.onCanvasSoft)
                }
            }
        }
        .monoPanel()
    }

    // MARK: Empty

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Mono.accentSoft)
            Text("Set your first goal")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Mono.onCanvas)
            Text("Pick something you'd love to save for — a bike, a trip, a rainy-day fund — and watch the bar fill up.")
                .font(.system(size: 14))
                .foregroundStyle(Mono.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Text("Add a goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Mono.plusInk)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 26)
                    .background(Mono.plus, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .monoPanel(padding: 28)
        .padding(.top, 8)
    }
}

/// A thin progress meter in the Mono palette.
struct MonoMeter: View {
    var value: Double                  // 0…1
    var tint: Color = Mono.accentSoft
    var height: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Mono.onCanvasSoft.opacity(0.22))
                Capsule().fill(tint)
                    .frame(width: max(height, min(1, max(0, value)) * geo.size.width))
            }
        }
        .frame(height: height)
        .accessibilityValue(percentText(value))
    }
}
