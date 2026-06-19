//
//  OnyxRootView.swift
//  PennyPath
//
//  The root of the "Onyx" reskin (Developer Mode only): the espresso glass
//  canvas with a frosted floating tab bar — Net Worth, Expenses, Goals,
//  Insights. Net Worth is the reskinned screen; the others are calm matching
//  placeholders.
//

import SwiftUI

enum OnyxTab: String, CaseIterable, Identifiable {
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

struct OnyxRootView: View {
    @State private var tab: OnyxTab = .netWorth

    var body: some View {
        ZStack {
            OnyxBackground()

            Group {
                switch tab {
                case .netWorth: OnyxNetWorthView()
                default: OnyxPlaceholder(tab: tab)
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            OnyxTabBar(tab: $tab)
        }
    }
}

// MARK: - Frosted tab bar

private struct OnyxTabBar: View {
    @Binding var tab: OnyxTab
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 0) {
            ForEach(OnyxTab.allCases) { item in
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
                    .foregroundStyle(tab == item ? Onyx.accent : Onyx.secondary)
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
        .padding(.horizontal, 10)
        .glassTabBarCapsule()
        .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }
}

// MARK: - Placeholder for the non-reskinned tabs

private struct OnyxPlaceholder: View {
    let tab: OnyxTab
    var body: some View {
        VStack(spacing: 14) {
            Image(systemName: tab.symbol)
                .font(.system(size: 44, weight: .regular))
                .foregroundStyle(Onyx.onCanvas)
            Text(tab.title)
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(Onyx.onCanvas)
            Text("Coming soon")
                .font(.system(size: 15))
                .foregroundStyle(Onyx.onCanvasSoft)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
