//
//  SlateRootView.swift
//  PennyPath
//
//  The root of the "Slate" reskin (Developer Mode only): the charcoal gradient
//  canvas with a white floating tab bar. Net Worth is the reskinned screen;
//  the other tabs are calm placeholders.
//

import SwiftUI

enum SlateTab: String, CaseIterable, Identifiable {
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

struct SlateRootView: View {
    @State private var tab: SlateTab = .netWorth

    var body: some View {
        ZStack {
            Slate.canvas.ignoresSafeArea()

            Group {
                switch tab {
                case .netWorth: SlateNetWorthView()
                default: SlatePlaceholder(tab: tab)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SlateTabBar(tab: $tab)
        }
    }
}

private struct SlateTabBar: View {
    @Binding var tab: SlateTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(SlateTab.allCases) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.easeInOut(duration: 0.2)) { tab = item }
                } label: {
                    VStack(spacing: 5) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 20, weight: .regular))
                        Text(item.title)
                            .font(.system(size: 11, weight: tab == item ? .semibold : .regular))
                    }
                    .foregroundStyle(tab == item ? Slate.accent : Slate.tabInactive)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background {
                        if tab == item {
                            RoundedRectangle(cornerRadius: 18, style: .continuous)
                                .fill(Color.primary.opacity(0.14))
                                .matchedGeometryEffect(id: "tabPill", in: pill)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .glassTabBarCapsule()
        .shadow(color: .black.opacity(0.15), radius: 16, y: 6)
        .padding(.horizontal, 20)
        .padding(.bottom, 6)
    }
}

private struct SlatePlaceholder: View {
    let tab: SlateTab
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: tab.symbol)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Slate.onCanvas)
            Text(tab.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Slate.onCanvas)
            Text("Coming soon")
                .font(.system(size: 15))
                .foregroundStyle(Slate.onCanvasSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
