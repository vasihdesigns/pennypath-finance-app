//
//  ClarityRootView.swift
//  PennyPath
//
//  The root of the "Clarity" reskin (Developer Mode only): four tabs —
//  Today, Spending, Worth, Goals — under the quietest possible tab bar.
//  Coaching lives inside Today rather than holding a tab of its own.
//  First visit opens Clarity's own short intro (separate from the real
//  app's onboarding), replayable from the advice screen.
//

import SwiftUI

enum ClarityTab: Hashable, CaseIterable {
    case today, spending, worth, goals

    var title: String {
        switch self {
        case .today: return "Today"
        case .spending: return "Spending"
        case .worth: return "Worth"
        case .goals: return "Goals"
        }
    }

    var symbol: String {
        switch self {
        case .today: return "sun.min"
        case .spending: return "list.bullet"
        case .worth: return "chart.line.uptrend.xyaxis"
        case .goals: return "flag"
        }
    }
}

struct ClarityRootView: View {
    @State private var tab: ClarityTab = .today
    // Clarity keeps its own first-run flag so the real app's onboarding
    // (didCompleteOnboarding) is never touched.
    @AppStorage("clarityDidOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            if didOnboard {
                shell.transition(.opacity)
            } else {
                ClarityOnboardingView {
                    withAnimation(.easeInOut(duration: 0.4)) { didOnboard = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var shell: some View {
        Group {
            switch tab {
            case .today: NavigationStack { ClarityTodayView(tab: $tab) }
            case .spending: NavigationStack { ClaritySpendView() }
            case .worth: NavigationStack { ClarityWorthView() }
            case .goals: NavigationStack { ClarityGoalsView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            ClarityTabBar(tab: $tab)
        }
    }
}

// MARK: - The quiet tab bar: a hairline, four marks, nothing else

private struct ClarityTabBar: View {
    @Binding var tab: ClarityTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(ClarityTab.allCases, id: \.self) { item in
                Button {
                    Haptics.tap()
                    tab = item
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 18, weight: tab == item ? .semibold : .regular))
                        Text(item.title)
                            .font(.caption2.weight(tab == item ? .semibold : .regular))
                    }
                    .foregroundStyle(tab == item ? Clarity.ink : Clarity.inkFaint)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.top, 6)
        .padding(.bottom, 2)
        .background(
            Clarity.paper
                .overlay(alignment: .top) { ClarityRule() }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}
