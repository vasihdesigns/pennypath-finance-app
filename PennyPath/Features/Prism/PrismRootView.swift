//
//  PrismRootView.swift
//  PennyPath
//
//  The root of the "Prism" reskin (Developer Mode only): four tabs — Worth,
//  Spend, Goals, Insights — on a flat neutral canvas under a floating tab
//  bar. Every money kind is a hue-coded gradient box. Brings its own first-run
//  intro and never touches the real onboarding flag.
//

import SwiftUI

enum PrismTab: Hashable, CaseIterable {
    case worth, spend, goals, insights

    var title: String {
        switch self {
        case .worth: return "Net Worth"
        case .spend: return "Spending"
        case .goals: return "Goals"
        case .insights: return "Insights"
        }
    }

    var symbol: String {
        switch self {
        case .worth: return "square.grid.2x2.fill"
        case .spend: return "creditcard.fill"
        case .goals: return "flag.fill"
        case .insights: return "sparkles"
        }
    }
}

struct PrismRootView: View {
    @State private var tab: PrismTab = .worth
    @AppStorage("prismDidOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            if didOnboard {
                shell.transition(.opacity)
            } else {
                PrismOnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) { didOnboard = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var shell: some View {
        Group {
            switch tab {
            case .worth: NavigationStack { PrismWorthView() }
            case .spend: NavigationStack { PrismSpendView() }
            case .goals: NavigationStack { PrismGoalsView() }
            case .insights: NavigationStack { PrismInsightsView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            PrismTabBar(tab: $tab)
        }
    }
}

// MARK: - Floating tab bar

private struct PrismTabBar: View {
    @Binding var tab: PrismTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(PrismTab.allCases, id: \.self) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { tab = item }
                } label: {
                    PrismTabItem(item: item, isActive: tab == item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Prism.surface)
                .overlay(Capsule().strokeBorder(Prism.hairline, lineWidth: 1))
                .shadow(color: .black.opacity(0.12), radius: 18, y: 7)
        )
        .padding(.horizontal, 22)
        .padding(.bottom, 4)
    }
}

private struct PrismTabItem: View {
    let item: PrismTab
    let isActive: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: item.symbol)
                .font(.system(size: 16, weight: .semibold))
            Text(item.title)
                .font(.system(size: 10, weight: isActive ? .bold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isActive ? .white : Prism.inkFaint)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background { if isActive { Capsule().fill(Prism.accent) } }
        .contentShape(Capsule())
    }
}
