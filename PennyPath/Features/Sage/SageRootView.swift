//
//  SageRootView.swift
//  PennyPath
//
//  The root of the "Sage" reskin (Developer Mode only): four tabs —
//  Worth, Spend, Goals, Coach — under a custom floating pill tab bar.
//  Home is gone; the Worth screen carries the greeting and the gear.
//

import SwiftUI

enum SageTab: Hashable, CaseIterable {
    case worth, spend, goals, coach

    var title: String {
        switch self {
        case .worth: return "Worth"
        case .spend: return "Spend"
        case .goals: return "Goals"
        case .coach: return "Coach"
        }
    }

    var symbol: String {
        switch self {
        case .worth: return "house"
        case .spend: return "creditcard"
        case .goals: return "smallcircle.circle"
        case .coach: return "sparkle"
        }
    }
}

struct SageRootView: View {
    @State private var tab: SageTab = .worth

    var body: some View {
        Group {
            switch tab {
            case .worth: NavigationStack { SageWorthView() }
            case .spend: NavigationStack { SageSpendView() }
            case .goals: NavigationStack { SageGoalsView() }
            case .coach: NavigationStack { SageCoachView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SageTabBar(tab: $tab)
        }
    }
}

// MARK: - Floating pill tab bar

private struct SageTabBar: View {
    @Binding var tab: SageTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SageTab.allCases, id: \.self) { item in
                Button {
                    Haptics.tap()
                    tab = item
                } label: {
                    SageTabItem(item: item, isActive: tab == item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, Sage.cardRadius / 2)
        .padding(.top, 10)
        .padding(.bottom, 4)
        .background(
            Sage.bg
                .overlay(alignment: .top) { Sage.hairline.frame(height: 0.5) }
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

private struct SageTabItem: View {
    let item: SageTab
    let isActive: Bool

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: item.symbol)
                .font(.system(size: 19, weight: .regular))
            Text(item.title)
                .font(.caption2.weight(isActive ? .semibold : .regular))
        }
        .foregroundStyle(isActive ? Sage.green : Sage.inkSoft)
        .padding(.horizontal, 16)
        .padding(.vertical, 9)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Sage.green.opacity(0.45), lineWidth: 1.2)
                    .background(
                        Sage.card.opacity(0.6),
                        in: RoundedRectangle(cornerRadius: 20, style: .continuous)
                    )
            }
        }
        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isActive)
    }
}
