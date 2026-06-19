//
//  SummitRootView.swift
//  PennyPath
//
//  The root of the "Summit" reskin (Developer Mode only): four tabs —
//  Net Worth, Expenses, Goals, AI Insights — under a clean flat tab bar on the
//  warm Summit canvas. Net Worth is the star (milestones live there). Brings
//  its own first-run intro and never touches the real onboarding flag.
//

import SwiftUI

enum SummitTab: String, CaseIterable, Identifiable {
    case worth, spend, goals, insights

    var id: String { rawValue }

    /// Full title shown at the top of each screen.
    var title: String {
        switch self {
        case .worth: return "Net Worth"
        case .spend: return "Expenses"
        case .goals: return "Goals"
        case .insights: return "AI Insights"
        }
    }

    /// Short label for the tab bar.
    var tabLabel: String {
        switch self {
        case .worth: return "Net Worth"
        case .spend: return "Expenses"
        case .goals: return "Goals"
        case .insights: return "Insights"
        }
    }

    var symbol: String {
        switch self {
        case .worth: return "chart.line.uptrend.xyaxis"
        case .spend: return "creditcard"
        case .goals: return "flag"
        case .insights: return "sparkles"
        }
    }
}

struct SummitRootView: View {
    @State private var tab: SummitTab = .worth
    /// Which Goals segment shows — bound here so the Net Worth milestone chip
    /// can deep-link straight onto Milestones.
    @State private var goalsSegment: SummitGoalsSegment = .goals
    @AppStorage("summitDidOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            if didOnboard {
                shell.transition(.opacity)
            } else {
                SummitOnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) { didOnboard = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var shell: some View {
        Group {
            switch tab {
            case .worth:
                NavigationStack {
                    SummitWorthView(onShowMilestones: {
                        goalsSegment = .milestones
                        tab = .goals
                    })
                }
            case .spend:
                NavigationStack { SummitSpendView() }
            case .goals:
                NavigationStack { SummitGoalsView(segment: $goalsSegment) }
            case .insights:
                NavigationStack {
                    SummitInsightsView(selectTab: { destination in
                        // A goal insight should land on the Goals list, not Milestones.
                        if destination == .goals { goalsSegment = .goals }
                        tab = destination
                    })
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SummitTabBar(tab: $tab)
        }
    }
}

// MARK: - Flat tab bar

private struct SummitTabBar: View {
    @Binding var tab: SummitTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SummitTab.allCases) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: .semibold))
                        Text(item.tabLabel)
                            .font(.system(size: 10, weight: .semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                    .foregroundStyle(tab == item ? Summit.accent : Summit.inkFaint)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 10)
        .padding(.bottom, 2)
        .background(
            Summit.card
                .overlay(Summit.hairline.frame(height: 1), alignment: .top)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
