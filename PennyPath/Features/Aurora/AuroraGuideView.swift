//
//  AuroraGuideView.swift
//  PennyPath
//
//  Aurora reskin of Coach: Nova — a breathing violet-mint orb — leads
//  with the headline insight, then the rest of the tips as glass cards.
//  Same on-device InsightsEngine; only the look changed. The footer can
//  replay Aurora's own intro tour.
//

import SwiftUI
import SwiftData

struct AuroraGuideView: View {
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]

    // Same default as AuroraRootView — the two must never disagree.
    @AppStorage("auroraDidOnboard") private var didOnboard = false

    private var insights: [Insight] {
        InsightsEngine.generate(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    /// Map the engine's tones onto Aurora's lights.
    private func tint(for insight: Insight) -> Color {
        switch insight.tone {
        case .positive: return Aurora.mint
        case .warning: return Aurora.coral
        case .tip: return Aurora.gold
        case .neutral: return Aurora.violet
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                header

                if let featured = insights.first {
                    VStack(alignment: .leading, spacing: 12) {
                        AuroraOverline(text: "Tonight's reading", tint: Aurora.violet)
                        Text(featured.message)
                            .font(.auroraDisplay(21, weight: .semibold))
                            .foregroundStyle(Aurora.ink)
                            .lineSpacing(4)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(featured.emoji + "  " + featured.title)
                            .font(.system(.footnote, design: .rounded).weight(.bold))
                            .foregroundStyle(tint(for: featured))
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .auroraCard(padding: 24, glow: Aurora.violet)
                }

                if insights.count > 1 {
                    VStack(alignment: .leading, spacing: 12) {
                        AuroraOverline(text: "More from Nova")
                        VStack(spacing: 12) {
                            ForEach(insights.dropFirst()) { insight in
                                tipCard(insight)
                            }
                        }
                    }
                }

                privacyNote
                replayButton
            }
            .padding(.horizontal, 22)
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .background(AuroraSky())
        .toolbar(.hidden, for: .navigationBar)
        .tint(Aurora.violet)
    }

    // MARK: Header

    private var header: some View {
        HStack(spacing: 16) {
            NovaOrb()
            VStack(alignment: .leading, spacing: 2) {
                Text("Nova")
                    .font(.auroraDisplay(28))
                    .foregroundStyle(Aurora.ink)
                Text("Reads your whole sky")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(Aurora.inkSoft)
            }
            Spacer(minLength: 0)
        }
    }

    // MARK: Tip cards

    private func tipCard(_ insight: Insight) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(insight.emoji)
                .font(.body)
                .frame(width: 36, height: 36)
                .background(tint(for: insight).opacity(0.14), in: Circle())
            VStack(alignment: .leading, spacing: 3) {
                Text(insight.title)
                    .font(.system(.subheadline, design: .rounded).weight(.bold))
                    .foregroundStyle(Aurora.ink)
                Text(insight.message)
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(Aurora.inkSoft)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .auroraCard(padding: 16)
    }

    private var privacyNote: some View {
        Text("🔒 Nova's readings are made right here on your phone from your own numbers — they're never sent anywhere. (Only investment price lookups use the internet.)")
            .font(.caption)
            .foregroundStyle(Aurora.inkFaint)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.top, 4)
    }

    private var replayButton: some View {
        Button {
            Haptics.tap()
            withAnimation(.easeInOut(duration: 0.5)) { didOnboard = false }
        } label: {
            Label("Replay the Aurora intro", systemImage: "play.rectangle")
                .font(.system(.footnote, design: .rounded).weight(.semibold))
                .foregroundStyle(Aurora.inkSoft)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Nova's face

/// A slowly breathing violet-mint orb with a single orbiting spark.
private struct NovaOrb: View {
    @State private var breathing = false

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Aurora.mint.opacity(0.9), Aurora.violet],
                        center: .init(x: 0.32, y: 0.28),
                        startRadius: 2, endRadius: 40
                    )
                )
                .frame(width: 54, height: 54)
                .shadow(color: Aurora.violet.opacity(0.7), radius: breathing ? 18 : 8)
                .scaleEffect(breathing ? 1.05 : 0.97)

            Circle()
                .fill(.white)
                .frame(width: 5)
                .offset(x: 34)
                .rotationEffect(.degrees(breathing ? 360 : 0))
                .shadow(color: Aurora.mint, radius: 3)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}
