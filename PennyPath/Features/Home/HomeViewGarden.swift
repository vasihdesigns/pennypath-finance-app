//
//  HomeViewGarden.swift
//  PennyPath
//
//  An experimental Home (Developer Mode only) with my own twist: a
//  "money garden". Your finances become a living scene — the weather
//  tracks budget health (sunny under budget, rain when over), every goal
//  grows as a plant whose stem rises with progress and blooms when it's
//  reached, and net worth sits on a little wooden sign in the grass.
//  The real HomeView is untouched.
//

import SwiftUI
import SwiftData

struct HomeViewGarden: View {
    @Binding var selectedTab: AppTab

    @Environment(AppStore.self) private var store
    @Environment(\.modelContext) private var context
    @Query private var accounts: [Account]
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @Query private var goals: [Goal]
    @Query private var budgets: [CategoryBudget]
    @Query(sort: \NetWorthSnapshot.date, order: .forward) private var snapshots: [NetWorthSnapshot]

    @State private var showingSettings = false

    // MARK: Numbers

    private var assets: Double { accounts.filter { $0.category.isAsset }.reduce(0) { $0 + $1.balance } }
    private var debts: Double { accounts.filter { !$0.category.isAsset }.reduce(0) { $0 + $1.balance } }
    private var netWorth: Double { assets - debts }

    /// Share of your money that's truly yours (debt-free). Healthier soil = richer grass.
    private var ownedProgress: Double {
        let total = assets + debts
        if total > 0 { return assets / total }
        return assets > 0 ? 1 : 0
    }

    private var monthSpending: Double {
        expenses.filter { $0.date.isSameMonth(as: .now) }.reduce(0) { $0 + $1.amount }
    }
    private var lastMonth: Double {
        expenses.filter { $0.date.isSameMonth(as: .now.adding(months: -1)) }.reduce(0) { $0 + $1.amount }
    }
    private var totalBudget: Double { budgets.reduce(0) { $0 + $1.monthlyLimit } }
    /// Budget used this month (falls back to vs last month if no budget set).
    private var budgetProgress: Double {
        if totalBudget > 0 { return monthSpending / totalBudget }
        if lastMonth > 0 { return monthSpending / lastMonth }
        return monthSpending > 0 ? 1 : 0
    }

    /// The forecast over the garden: spend lightly and the sun shines.
    private var weather: GardenWeather {
        if budgetProgress < 0.7 { return .sunny }
        if budgetProgress <= 1.0 { return .overcast }
        return .rainy
    }

    private var totalSaved: Double { goals.reduce(0) { $0 + $1.savedAmount } }
    private var totalTarget: Double { goals.reduce(0) { $0 + $1.targetAmount } }
    private var goalsProgress: Double { totalTarget > 0 ? totalSaved / totalTarget : 0 }

    /// The plants in the bed: up to five goals, tallest first so the
    /// garden reads like a little skyline.
    private var plantedGoals: [Goal] {
        Array(goals.sorted { $0.progress > $1.progress }.prefix(5))
    }

    private var headline: Insight {
        InsightsEngine.headline(accounts: accounts, expenses: expenses, goals: goals, budgets: budgets)
    }

    // MARK: Body

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Space.xl) {
                if store.isDemo { demoBanner }

                gardenCard
                vitalsRow
                gardenersNote
            }
            .padding(Theme.Space.lg)
        }
        .background(Theme.background)
        .navigationTitle(InsightsEngine.greeting())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showingSettings = true } label: { Image(systemName: "gearshape") }
                    .tint(Theme.ink)
            }
        }
        .sheet(isPresented: $showingSettings) { SettingsView() }
        .onAppear { NetWorthHistory.record(in: context) }
        .onChange(of: netWorth) { _, _ in NetWorthHistory.record(in: context) }
    }

    // MARK: The garden scene

    private var gardenCard: some View {
        VStack(spacing: 0) {
            GardenScene(
                weather: weather,
                netWorth: netWorth,
                goals: plantedGoals,
                onTapPlant: { selectedTab = .goals },
                onTapSign: { selectedTab = .netWorth }
            )
            .frame(height: 280)
            .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))

            HStack {
                Label(weather.caption, systemImage: weather.symbol)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(weather == .rainy ? Theme.red : Theme.inkSecondary)
                Spacer()
                if goals.isEmpty {
                    Button { selectedTab = .goals } label: {
                        Label("Plant a goal", systemImage: "leaf.fill")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(Theme.green)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text("\(goals.filter(\.isComplete).count) of \(goals.count) in bloom")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.gold)
                }
            }
            .padding(.horizontal, Theme.Space.lg)
            .padding(.vertical, Theme.Space.md)
        }
        .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }

    // MARK: Garden vitals — soil, bloom, rain

    private var vitalsRow: some View {
        HStack(spacing: Theme.Space.md) {
            vital(emoji: "🪴", title: "Soil", detail: "yours",
                  value: ownedProgress, color: Theme.green, tab: .netWorth)
            vital(emoji: "🌼", title: "Bloom", detail: "of goals",
                  value: goalsProgress, color: Theme.gold, tab: .goals)
            vital(emoji: "💧", title: "Rain", detail: "of budget",
                  value: budgetProgress, color: Theme.red, tab: .expenses)
        }
    }

    private func vital(emoji: String, title: String, detail: String,
                       value: Double, color: Color, tab: AppTab) -> some View {
        Button { selectedTab = tab } label: {
            VStack(spacing: 6) {
                Text(emoji).font(.title3)
                Text(percentText(min(value, 9.99)))
                    .font(.amount(18))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text("\(title) · \(detail)")
                    .font(.caption2)
                    .foregroundStyle(Theme.inkSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, Theme.Space.md)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: Demo banner + gardener's note

    private var demoBanner: some View {
        HStack(spacing: Theme.Space.md) {
            Text("👀").font(.title3)
            VStack(alignment: .leading, spacing: 1) {
                Text("Demo data").font(.subheadline.weight(.bold)).foregroundStyle(Theme.ink)
                Text("Exploring an example world. Your real data is safe.")
                    .font(.caption).foregroundStyle(Theme.inkSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(Theme.Space.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.gold.opacity(0.16),
                    in: RoundedRectangle(cornerRadius: Theme.Radius.panel, style: .continuous))
    }

    private var gardenersNote: some View {
        VStack(alignment: .leading, spacing: Theme.Space.md) {
            SectionHeader(title: "Gardener's note", actionTitle: "See all") { selectedTab = .coach }
            InsightCard(insight: headline)
        }
    }

    // MARK: History — real points only (NetWorthHistory)
}

// MARK: - Weather over the garden

private enum GardenWeather {
    case sunny, overcast, rainy

    var symbol: String {
        switch self {
        case .sunny: return "sun.max.fill"
        case .overcast: return "cloud.sun.fill"
        case .rainy: return "cloud.rain.fill"
        }
    }

    var caption: String {
        switch self {
        case .sunny: return "Sunny — spending is under control"
        case .overcast: return "Clouding over — budget almost used"
        case .rainy: return "Raining — over budget this month"
        }
    }

    /// Top → bottom sky colors, tuned for light and dark mode.
    var sky: [Color] {
        switch self {
        case .sunny:
            return [Color.adaptive(light: 0x8ECDF2, dark: 0x0E2A47),
                    Color.adaptive(light: 0xDFF2FD, dark: 0x1B3B5C)]
        case .overcast:
            return [Color.adaptive(light: 0x9FB2C4, dark: 0x232E3B),
                    Color.adaptive(light: 0xD7E0E8, dark: 0x35424F)]
        case .rainy:
            return [Color.adaptive(light: 0x6E8296, dark: 0x161D26),
                    Color.adaptive(light: 0xAEBDCB, dark: 0x2A3540)]
        }
    }
}

// MARK: - The scene: sky, weather, hill, plants, net-worth sign

private struct GardenScene: View {
    let weather: GardenWeather
    let netWorth: Double
    let goals: [Goal]
    var onTapPlant: () -> Void
    var onTapSign: () -> Void

    @State private var grown = false

    var body: some View {
        ZStack(alignment: .bottom) {
            LinearGradient(colors: weather.sky, startPoint: .top, endPoint: .bottom)

            skyDetail

            if weather == .rainy { RainLayer() }

            hill

            // The flower bed, planted along the brow of the hill.
            HStack(alignment: .bottom, spacing: Theme.Space.lg) {
                if goals.isEmpty {
                    EmptyBed()
                } else {
                    ForEach(goals) { goal in
                        GoalPlant(goal: goal, grown: grown)
                    }
                }
            }
            .padding(.bottom, 58)
            .contentShape(Rectangle())
            .onTapGesture { onTapPlant() }

            netWorthSign
        }
        .onAppear {
            withAnimation(.spring(response: 1.1, dampingFraction: 0.7).delay(0.15)) {
                grown = true
            }
        }
    }

    /// Sun for clear days, a drifting cloud otherwise.
    private var skyDetail: some View {
        VStack {
            HStack {
                Spacer()
                Image(systemName: weather.symbol)
                    .font(.system(size: 44))
                    .symbolRenderingMode(.multicolor)
                    .shadow(color: weather == .sunny ? Theme.gold.opacity(0.5) : .clear, radius: 14)
                    .padding(.top, Theme.Space.xl)
                    .padding(.trailing, Theme.Space.xxl)
            }
            Spacer()
        }
    }

    private var hill: some View {
        HillShape()
            .fill(
                LinearGradient(
                    colors: [Color.adaptive(light: 0x6FBE6C, dark: 0x1F5E33),
                             Color.adaptive(light: 0x4C9B52, dark: 0x14401F)],
                    startPoint: .top, endPoint: .bottom)
            )
            .frame(height: 96)
    }

    private var netWorthSign: some View {
        Button(action: onTapSign) {
            VStack(spacing: 0) {
                VStack(spacing: 1) {
                    Text("NET WORTH")
                        .font(.system(size: 8, weight: .bold, design: .rounded))
                        .tracking(1)
                        .foregroundStyle(.white.opacity(0.75))
                    Text(money(netWorth))
                        .font(.amount(15))
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding(.horizontal, Theme.Space.md)
                .padding(.vertical, 6)
                .background(
                    Color.adaptive(light: 0x7A5230, dark: 0x5C3D22),
                    in: RoundedRectangle(cornerRadius: 8, style: .continuous)
                )
                // The post the sign stands on.
                Rectangle()
                    .fill(Color.adaptive(light: 0x6B4628, dark: 0x4A301B))
                    .frame(width: 6, height: 18)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Theme.Space.xl)
        .padding(.bottom, Theme.Space.lg)
    }
}

/// A gentle two-bump hill across the bottom of the scene.
private struct HillShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.45))
        p.addQuadCurve(
            to: CGPoint(x: rect.midX, y: rect.minY + rect.height * 0.2),
            control: CGPoint(x: rect.width * 0.22, y: rect.minY - rect.height * 0.1))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.5),
            control: CGPoint(x: rect.width * 0.78, y: rect.minY + rect.height * 0.55))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        p.closeSubpath()
        return p
    }
}

/// One goal as a plant: the stem grows with progress and the head blooms
/// into the goal's emoji once it's complete (a bud until then).
private struct GoalPlant: View {
    let goal: Goal
    let grown: Bool

    private var progress: Double { max(0, min(1, goal.progress)) }
    private var stemHeight: CGFloat { 14 + 64 * progress }

    var body: some View {
        VStack(spacing: 0) {
            Text(goal.isComplete ? goal.emoji : "🌱")
                .font(.system(size: goal.isComplete ? 26 : 16))
                .scaleEffect(grown ? 1 : 0.1, anchor: .bottom)
                .shadow(color: goal.isComplete ? Theme.gold.opacity(0.6) : .clear, radius: 8)

            Capsule()
                .fill(Color.adaptive(light: 0x2F7D3A, dark: 0x57B16A))
                .frame(width: 4, height: grown ? stemHeight : 2)
        }
        .accessibilityLabel("\(goal.name), \(percentText(progress)) saved")
    }
}

/// Shown when no goals exist yet — a patch of soil waiting for seeds.
private struct EmptyBed: View {
    var body: some View {
        VStack(spacing: 4) {
            Text("🫘")
                .font(.title3)
            Text("Tap to plant your first goal")
                .font(.caption2.weight(.semibold))
                .foregroundStyle(.white.opacity(0.9))
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(.black.opacity(0.25), in: Capsule())
        }
    }
}

/// Light diagonal rain when the month has gone over budget.
private struct RainLayer: View {
    @State private var fall = false

    var body: some View {
        GeometryReader { geo in
            ForEach(0..<14, id: \.self) { i in
                Capsule()
                    .fill(Color.white.opacity(0.35))
                    .frame(width: 2, height: 12)
                    .rotationEffect(.degrees(12))
                    .position(
                        x: CGFloat((i * 73) % Int(max(geo.size.width, 1))),
                        y: fall ? geo.size.height + 20 : -20
                    )
                    .animation(
                        .linear(duration: 1.1)
                        .repeatForever(autoreverses: false)
                        .delay(Double(i) * 0.13),
                        value: fall
                    )
            }
        }
        .allowsHitTesting(false)
        .onAppear { fall = true }
    }
}
