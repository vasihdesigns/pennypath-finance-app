//
//  SpectrumGoalsView.swift
//  PennyPath
//
//  Spectrum's Goals screen on real data: how far you are across everything you're
//  saving toward, then each goal as a card with a grey bar that fills as you
//  go. Taps open the real Goal detail; the + adds a goal with the real form.
//

import SwiftUI
import SwiftData

struct SpectrumGoalsView: View {
    @Environment(\.modelContext) private var context
    // Archived goals are hidden from the list, the summary, and insights.
    @Query(filter: #Predicate<Goal> { !$0.isArchived },
           sort: \Goal.createdAt, order: .forward) private var goals: [Goal]
    // Archived accounts don't count toward net worth or milestones.
    @Query(filter: #Predicate<Account> { !$0.isArchived }) private var accounts: [Account]
    @AppStorage(AppSettings.currencyKey) private var currencyCode = "USD"

    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var section: Section = .goals

    enum Section: String, CaseIterable, Identifiable {
        case goals = "Goals", milestones = "Milestones"
        var id: String { rawValue }
    }

    // A completed goal reads in the palette's teal — a clear "done / positive".
    private let done = Spectrum.good

    /// Ink for a checkmark/crown sitting on a jewel medal. The medal fill comes
    /// from `Spectrum.palette`, which is DEEP in light mode (white reads) but
    /// BRIGHT in dark mode (white washes out) — so the ink flips to near-black in
    /// dark, keeping the glyph crisp on every tone in both appearances.
    private let medalInk = Color.adaptive(light: 0xFFFFFF, dark: 0x131315)

    // MARK: Net-worth milestones

    /// The wealth ladder net worth climbs through.
    private let ladder: [Double] = [1_000, 5_000, 10_000, 25_000, 50_000, 100_000,
                                    250_000, 500_000, 1_000_000, 2_500_000, 5_000_000]
    private var netWorth: Double { accounts.reduce(0) { $0 + $1.signedBalance } }
    private var nextMilestone: Double? { ladder.first { $0 > netWorth } }
    private var lastReached: Double { ladder.last { netWorth >= $0 } ?? 0 }
    /// All reached rungs plus the next few to aim for (no endless locked list).
    private var visibleMilestones: [Double] {
        ladder.filter { netWorth >= $0 } + ladder.filter { $0 > netWorth }.prefix(4)
    }

    /// Every rung already cleared, smallest → largest (the medals earned).
    private var reachedLadder: [Double] { ladder.filter { netWorth >= $0 } }
    private var reachedCount: Int { reachedLadder.count }
    /// Each earned medal wears its own jewel tone so the trail reads as a
    /// collection of distinct achievements, not one repeated badge.
    private func medalColor(_ m: Double) -> Color {
        let rank = reachedLadder.firstIndex(of: m) ?? 0
        return Spectrum.palette[rank % Spectrum.palette.count]
    }
    /// How far net worth has climbed from the last rung toward the given one (0…1).
    private func progressTo(_ m: Double) -> Double {
        let base = lastReached
        guard m - base > 0 else { return 0 }
        return min(1, max(0, (netWorth - base) / (m - base)))
    }

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var overallProgress: Double { totalTarget > 0 ? min(1, totalSaved / totalTarget) : 0 }
    private var completedCount: Int { goals.filter(\.isComplete).count }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                SpectrumHeader(title: "Goals") { showingSettings = true }
                SpectrumSegmented(items: Section.allCases, title: \.rawValue, selection: $section)
                switch section {
                case .goals:      goalsContent
                case .milestones: milestonesContent
                }
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 96)   // clear the floating tab bar
        }
        .scrollIndicators(.hidden)
        .background(Spectrum.canvas.ignoresSafeArea())
        .toolbar(.hidden, for: .navigationBar)
        .overlay(alignment: .bottomTrailing) {
            // Milestones are automatic — only Goals has something to add.
            if section == .goals {
                SpectrumPlusButton { showingAdd = true }
                    .padding(.trailing, 22)
                    .padding(.bottom, 58)   // sit just above the floating tab bar
            }
        }
        .sheet(isPresented: $showingAdd) { GoalFormView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    // MARK: Goals section

    @ViewBuilder private var goalsContent: some View {
        if goals.isEmpty {
            emptyCard
        } else {
            summaryCard
            ForEach(Array(goals.enumerated()), id: \.element.id) { index, goal in
                NavigationLink {
                    GoalDetailView(goal: goal)
                } label: {
                    goalCard(goal, color: Spectrum.palette[index % Spectrum.palette.count])
                }
                .buttonStyle(.plain)
                .contextMenu {
                    Button("Archive", systemImage: "archivebox") { archive(goal) }
                    Button("Delete", systemImage: "trash", role: .destructive) {
                        context.delete(goal)
                    }
                }
            }
        }
    }

    /// Soft-hide a goal — it leaves the list and the saved-so-far summary at once,
    /// but the record is kept and can be restored from Settings → Archived.
    private func archive(_ goal: Goal) {
        Haptics.tap()
        withAnimation(.snappy) {
            goal.isArchived = true
            goal.archivedAt = .now
        }
    }

    // MARK: Milestones section

    @ViewBuilder private var milestonesContent: some View {
        milestoneHero
        milestoneTrail
    }

    /// A small teal "N reached" badge — the trophy count shared by both heroes.
    private func reachedPill(_ count: Int) -> some View {
        HStack(spacing: 5) {
            Image(systemName: "rosette")
            Text("\(count) reached")
        }
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(done)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(done.opacity(0.14), in: Capsule())
    }

    // MARK: Hero — where you stand + medals already earned

    private var milestoneHero: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("NET WORTH")
                    .font(.system(size: 11, weight: .semibold)).tracking(1)
                    .foregroundStyle(Spectrum.onCanvasSoft)
                Spacer()
                if reachedCount > 0 { reachedPill(reachedCount) }
            }
            Text(money(netWorth, code: currencyCode))
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(netWorth >= 0 ? Spectrum.onCanvas : Spectrum.spend)
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            if let next = nextMilestone {
                SpectrumMeter(value: progressTo(next), tint: Spectrum.accentSoft)
                Text("\(money(max(0, next - netWorth), code: currencyCode)) to your next milestone — \(money(next, code: currencyCode))")
                    .font(.system(size: 13))
                    .foregroundStyle(Spectrum.onCanvasSoft)
            } else {
                Text("🏆 You've reached every milestone. Incredible.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(done)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .spectrumPanel(padding: 18)
    }

    // MARK: Trail — a single climb threaded through every milestone

    private var milestoneTrail: some View {
        let rows = visibleMilestones   // ascending: smallest → largest, reading top → bottom
        let showBase = reachedCount > 0
        return VStack(spacing: 0) {
            if showBase { trailBase }   // where it began ($0) anchors the top
            ForEach(Array(rows.enumerated()), id: \.offset) { i, m in
                // A leg between two rungs is "climbed" once net worth passes the
                // larger of the pair — which now sits BELOW. So the gap above this
                // node is solid iff this node is reached; the gap below is solid
                // iff the next (larger) node is reached.
                let belowReached = i < rows.count - 1 && netWorth >= rows[i + 1]
                milestoneStop(m,
                              upperFilled: netWorth >= m,
                              lowerFilled: belowReached,
                              showUpper: i > 0 || showBase,
                              showLower: i < rows.count - 1)
            }
        }
        .spectrumPanel(padding: 8)
    }

    private func milestoneStop(_ m: Double,
                               upperFilled: Bool,
                               lowerFilled: Bool,
                               showUpper: Bool,
                               showLower: Bool) -> some View {
        let reached = netWorth >= m
        let isNext = m == nextMilestone
        return HStack(alignment: .center, spacing: 14) {
            trailRail(m, upperFilled: upperFilled, lowerFilled: lowerFilled,
                      showUpper: showUpper, showLower: showLower)
                .frame(width: 54)
            milestoneLabel(m, reached: reached, isNext: isNext)
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: isNext ? 78 : 62)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(milestoneA11y(m, reached: reached, isNext: isNext))
    }

    // The spine + the node, layered so the line runs edge-to-edge of the row
    // (rows sit at zero spacing, so the segments meet into one continuous climb).
    private func trailRail(_ m: Double,
                           upperFilled: Bool,
                           lowerFilled: Bool,
                           showUpper: Bool,
                           showLower: Bool) -> some View {
        ZStack {
            VStack(spacing: 0) {
                railSegment(filled: upperFilled, visible: showUpper)
                railSegment(filled: lowerFilled, visible: showLower)
            }
            milestoneNode(m)
        }
    }

    @ViewBuilder
    private func railSegment(filled: Bool, visible: Bool) -> some View {
        if visible {
            VLine()
                .stroke(filled ? done : Spectrum.onCanvasSoft.opacity(0.30),
                        style: StrokeStyle(lineWidth: filled ? 4 : 2,
                                           lineCap: .round,
                                           dash: filled ? [] : [2, 7]))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func milestoneNode(_ m: Double) -> some View {
        let reached = netWorth >= m
        let isNext = m == nextMilestone
        let isPeak = m == ladder.last
        if reached {
            let c = medalColor(m)
            ZStack {
                Circle().fill(c)
                    .frame(width: 38, height: 38)
                    .shadow(color: c.opacity(0.55), radius: 6, y: 2)
                Image(systemName: isPeak ? "crown.fill" : "checkmark")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(medalInk)
            }
            .overlay(Circle().strokeBorder(.white.opacity(0.25), lineWidth: 1).frame(width: 38, height: 38))
        } else if isNext {
            let frac = progressTo(m)
            ZStack {
                Circle().stroke(Spectrum.onCanvasSoft.opacity(0.18), lineWidth: 5)
                Circle().trim(from: 0, to: max(0.015, frac))
                    .stroke(Spectrum.accentSoft, style: StrokeStyle(lineWidth: 5, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Text(percentText(frac))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Spectrum.accentSoft)
            }
            .frame(width: 52, height: 52)
            .shadow(color: Spectrum.accentSoft.opacity(0.35), radius: 8)
        } else {
            ZStack {
                Circle().fill(Spectrum.onCanvasSoft.opacity(0.14))
                    .frame(width: 30, height: 30)
                Image(systemName: isPeak ? "crown" : "lock.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvasSoft.opacity(0.7))
            }
        }
    }

    private func milestoneLabel(_ m: Double, reached: Bool, isNext: Bool) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            if isNext {
                Text("NEXT UP")
                    .font(.system(size: 10, weight: .heavy)).tracking(1.2)
                    .foregroundStyle(Spectrum.accentSoft)
            }
            Text(money(m, code: currencyCode))
                .font(.system(size: isNext ? 20 : 17, weight: .bold))
                .foregroundStyle(reached || isNext ? Spectrum.onCanvas : Spectrum.onCanvasSoft)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            Group {
                if reached {
                    Label("Reached", systemImage: "checkmark.seal.fill")
                        .foregroundStyle(medalColor(m))
                } else if isNext {
                    Text("\(money(max(0, m - netWorth), code: currencyCode)) to go")
                        .foregroundStyle(Spectrum.accentSoft)
                } else {
                    Text("Locked")
                        .foregroundStyle(Spectrum.onCanvasSoft.opacity(0.7))
                }
            }
            .font(.system(size: 12.5, weight: .semibold))
        }
    }

    /// The head of the climb — where every journey began ($0), sitting above the
    /// first rung, its connector running down into it.
    private var trailBase: some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                VStack(spacing: 0) {
                    Color.clear.frame(maxWidth: .infinity, maxHeight: .infinity)
                    railSegment(filled: true, visible: true)
                }
                Circle().fill(done).frame(width: 12, height: 12)
            }
            .frame(width: 54)
            Text("Where it started — \(money(0, code: currencyCode))")
                .font(.system(size: 12.5, weight: .medium))
                .foregroundStyle(Spectrum.onCanvasSoft)
            Spacer(minLength: 8)
        }
        .padding(.horizontal, 8)
        .frame(minHeight: 46)
    }

    private func milestoneA11y(_ m: Double, reached: Bool, isNext: Bool) -> String {
        let amount = money(m, code: currencyCode)
        if reached { return "\(amount) milestone, reached" }
        if isNext { return "\(amount) milestone, next up, \(percentText(progressTo(m))) there" }
        return "\(amount) milestone, locked"
    }

    // MARK: Summary

    private var summaryCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Text("SAVED SO FAR")
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(1)
                    .foregroundStyle(Spectrum.onCanvasSoft)
                Spacer()
                if completedCount > 0 { reachedPill(completedCount) }
            }
            HStack(alignment: .firstTextBaseline) {
                Text(money(totalSaved, code: currencyCode))
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvas)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(percentText(overallProgress))
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(Spectrum.accentSoft)
            }
            SpectrumMeter(value: overallProgress, tint: Spectrum.accentSoft)
            Text("of \(money(totalTarget, code: currencyCode)) across \(goals.count) goal\(goals.count == 1 ? "" : "s")")
                .font(.system(size: 13))
                .foregroundStyle(Spectrum.onCanvasSoft)
        }
        .spectrumPanel()
    }

    // MARK: Goal card — a progress dial that celebrates when it fills up

    private func goalCard(_ goal: Goal, color: Color) -> some View {
        let tint = goal.isComplete ? done : color
        return HStack(spacing: 16) {
            goalRing(goal, tint: tint)
            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 8) {
                    Text(goal.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Spectrum.onCanvas)
                        .lineLimit(1)
                    Spacer(minLength: 4)
                    Text(goal.isComplete ? "Done 🎉" : percentText(goal.progress))
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(tint)
                }
                Text("\(money(goal.savedAmount, code: currencyCode)) of \(money(goal.targetAmount, code: currencyCode))")
                    .font(.system(size: 12.5))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                goalFooter(goal, tint: tint)
            }
        }
        .spectrumPanel()
    }

    /// The circular dial: the goal's emoji ringed by its progress, glowing and
    /// sealed once it's complete (echoing the milestone medals).
    private func goalRing(_ goal: Goal, tint: Color) -> some View {
        ZStack {
            Circle().stroke(Spectrum.onCanvasSoft.opacity(0.16), lineWidth: 6)
            Circle().trim(from: 0, to: max(0.02, goal.progress))
                .stroke(tint, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(goal.emoji).font(.system(size: 23))
        }
        .frame(width: 60, height: 60)
        .shadow(color: goal.isComplete ? tint.opacity(0.45) : .clear, radius: 8)
        .overlay(alignment: .bottomTrailing) {
            if goal.isComplete {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 19, weight: .bold))
                    .foregroundStyle(medalInk, tint)
                    .offset(x: 3, y: 3)
            }
        }
    }

    @ViewBuilder
    private func goalFooter(_ goal: Goal, tint: Color) -> some View {
        if goal.isComplete {
            Label("Reached", systemImage: "checkmark.seal.fill")
                .font(.system(size: 12.5, weight: .semibold))
                .foregroundStyle(tint)
        } else {
            HStack(spacing: 8) {
                if let monthly = goal.suggestedMonthly {
                    Label("\(money(monthly, code: currencyCode))/mo", systemImage: "calendar")
                        .lineLimit(1)
                } else if let date = goal.targetDate {
                    Label("by \(date.monthYear)", systemImage: "calendar")
                }
                Spacer(minLength: 4)
                Text("\(money(goal.remaining, code: currencyCode)) to go")
                    .fontWeight(.medium)
            }
            .font(.system(size: 12.5))
            .foregroundStyle(Spectrum.onCanvasSoft)
        }
    }

    // MARK: Empty

    private var emptyCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "flag")
                .font(.system(size: 38, weight: .semibold))
                .foregroundStyle(Spectrum.accentSoft)
            Text("Set your first goal")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvas)
            Text("Pick something you'd love to save for — a bike, a trip, a rainy-day fund — and watch the bar fill up.")
                .font(.system(size: 14))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
            Button {
                Haptics.tap()
                showingAdd = true
            } label: {
                Text("Add a goal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Spectrum.plusInk)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 26)
                    .background(Spectrum.plus, in: Capsule())
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .spectrumPanel(padding: 28)
        .padding(.top, 8)
    }
}

/// A vertical line down the centre of its frame — the spine of the milestone climb.
private struct VLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.midX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return p
    }
}

/// A thin progress meter in the Spectrum palette.
struct SpectrumMeter: View {
    var value: Double                  // 0…1
    var tint: Color = Spectrum.accentSoft
    var height: CGFloat = 9

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Spectrum.onCanvasSoft.opacity(0.22))
                Capsule().fill(tint)
                    .frame(width: max(height, min(1, max(0, value)) * geo.size.width))
            }
        }
        .frame(height: height)
        .accessibilityValue(percentText(value))
    }
}
