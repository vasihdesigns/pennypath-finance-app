//
//  MonoRootView.swift
//  PennyPath
//
//  The app's main shell: a black & white grayscale canvas with a white floating tab bar
//  — Net Worth, Expenses, Goals, Insights. Every tab reads the real store and
//  reuses the real forms and services; only the look is Mono's. There is no
//  Home tab — Net Worth is the home base.
//

import SwiftUI

enum MonoTab: String, CaseIterable, Identifiable {
    case netWorth, expenses, goals, insights
    var id: String { rawValue }

    var title: String {
        switch self {
        case .netWorth: return "Net Worth"
        case .expenses: return "Expenses"
        case .goals: return "Goals"
        case .insights: return "Insights"
        }
    }

    var symbol: String {
        switch self {
        case .netWorth: return "chart.line.uptrend.xyaxis"
        case .expenses: return "creditcard"
        case .goals: return "flag"
        case .insights: return "sparkles"
        }
    }
}

struct MonoRootView: View {
    @State private var tab: MonoTab = .netWorth

    var body: some View {
        ZStack {
            Mono.canvas.ignoresSafeArea()

            Group {
                switch tab {
                case .netWorth:
                    NavigationStack { MonoNetWorthView() }
                case .expenses:
                    NavigationStack { MonoExpensesView() }
                case .goals:
                    NavigationStack { MonoGoalsView() }
                case .insights:
                    NavigationStack {
                        MonoInsightsView(selectTab: { destination in
                            withAnimation(.easeInOut(duration: 0.2)) { tab = destination }
                        })
                    }
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            MonoTabBar(tab: $tab)
        }
    }
}

// MARK: - White floating tab bar

private struct MonoTabBar: View {
    @Binding var tab: MonoTab
    @Namespace private var glassNS

    var body: some View {
        HStack(spacing: 0) {
            ForEach(MonoTab.allCases) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.smooth(duration: 0.38)) { tab = item }
                } label: {
                    VStack(spacing: 3) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 19, weight: tab == item ? .semibold : .regular))
                            .symbolVariant(tab == item ? .fill : .none)
                        Text(item.title)
                            .font(.system(size: 11, weight: tab == item ? .semibold : .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(tab == item ? Mono.accentSoft : Mono.tabInactive)
                    .padding(.vertical, 6)
                    .padding(.horizontal, 12)
                    .frame(maxWidth: .infinity)
                    .background { selectionGlass(for: item) }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .glassTabBarCapsule()
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, -16)   // pull down into the home-indicator gap
    }

    /// The selected tab's backing — a Liquid Glass capsule that fluidly slides
    /// (and refracts the canvas) as you switch tabs on iOS 26; a soft frosted
    /// capsule on earlier systems.
    @ViewBuilder
    private func selectionGlass(for item: MonoTab) -> some View {
        if tab == item {
            if #available(iOS 26.0, *) {
                Color.clear
                    .glassEffect(.regular.interactive(), in: Capsule())
                    .matchedGeometryEffect(id: "monoTabSelection", in: glassNS)
            } else {
                Capsule()
                    .fill(.white.opacity(0.12))
                    .matchedGeometryEffect(id: "monoTabSelection", in: glassNS)
            }
        }
    }
}
