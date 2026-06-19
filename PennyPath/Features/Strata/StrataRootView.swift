//
//  StrataRootView.swift
//  PennyPath
//
//  The root of the "Strata" reskin (Developer Mode only): four tabs —
//  Worth, Spend, Goals, Coach — under a white floating tab bar on the
//  periwinkle canvas. Worth is the star (net worth as proportional strata).
//  Brings its own first-run intro and never touches the real onboarding flag.
//

import SwiftUI

enum StrataTab: Hashable, CaseIterable {
    case worth, spend, goals, coach

    var title: String {
        switch self {
        case .worth: return "Worth"
        case .spend: return "Cash Flow"
        case .goals: return "Goals"
        case .coach: return "Insights"
        }
    }

    var symbol: String {
        switch self {
        case .worth: return "square.stack.3d.up.fill"
        case .spend: return "arrow.left.arrow.right"
        case .goals: return "flag.fill"
        case .coach: return "lightbulb.fill"
        }
    }
}

struct StrataRootView: View {
    @State private var tab: StrataTab = .worth
    @AppStorage("strataDidOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            if didOnboard {
                shell.transition(.opacity)
            } else {
                StrataOnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) { didOnboard = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var shell: some View {
        Group {
            switch tab {
            case .worth: NavigationStack { StrataWorthView() }
            case .spend: NavigationStack { StrataSpendView() }
            case .goals: NavigationStack { StrataGoalsView() }
            case .coach: NavigationStack { StrataCoachView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            StrataTabBar(tab: $tab)
        }
    }
}

// MARK: - White floating tab bar

private struct StrataTabBar: View {
    @Binding var tab: StrataTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StrataTab.allCases, id: \.self) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.82)) { tab = item }
                } label: {
                    StrataTabItem(item: item, isActive: tab == item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Strata.card)
                .shadow(color: .black.opacity(0.18), radius: 20, y: 8)
        )
        .padding(.horizontal, 22)
        .padding(.bottom, 4)
    }
}

private struct StrataTabItem: View {
    let item: StrataTab
    let isActive: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .semibold))
            Text(item.title)
                .font(.system(size: 10, weight: isActive ? .bold : .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(isActive ? .white : Strata.inkFaint)
        .padding(.vertical, 8)
        .frame(maxWidth: .infinity)
        .background {
            if isActive {
                Capsule().fill(Strata.bg)
            }
        }
        .contentShape(Capsule())
    }
}
