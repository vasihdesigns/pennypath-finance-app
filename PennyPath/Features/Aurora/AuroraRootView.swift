//
//  AuroraRootView.swift
//  PennyPath
//
//  The root of the "Aurora" reskin (Developer Mode only): four tabs —
//  Pulse, Flow, Quests, Nova — under a floating glass tab bar, all on a
//  starfield. The first visit opens with Aurora's own onboarding tour
//  (separate from the real app's), replayable from the Nova tab.
//

import SwiftUI

enum AuroraTab: Hashable, CaseIterable {
    case pulse, flow, quests, nova

    var title: String {
        switch self {
        case .pulse: return "Pulse"
        case .flow: return "Flow"
        case .quests: return "Quests"
        case .nova: return "Nova"
        }
    }

    var symbol: String {
        switch self {
        case .pulse: return "waveform.path.ecg"
        case .flow: return "wind"
        case .quests: return "moon.stars"
        case .nova: return "sparkles"
        }
    }

    var accent: Color {
        switch self {
        case .pulse: return Aurora.mint
        case .flow: return Aurora.pink
        case .quests: return Aurora.gold
        case .nova: return Aurora.violet
        }
    }
}

struct AuroraRootView: View {
    @State private var tab: AuroraTab = .pulse
    // Aurora keeps its own first-run flag so the real app's onboarding
    // (didCompleteOnboarding) is never touched.
    @AppStorage("auroraDidOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            if didOnboard {
                shell
                    .transition(.opacity)
            } else {
                AuroraOnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) { didOnboard = true }
                }
                .transition(.opacity)
            }
        }
        // Aurora is a night theme by design: force dark so embedded real
        // forms and sheets stay legible against the sky.
        .preferredColorScheme(.dark)
    }

    private var shell: some View {
        Group {
            switch tab {
            case .pulse: NavigationStack { AuroraPulseView() }
            case .flow: NavigationStack { AuroraFlowView() }
            case .quests: NavigationStack { AuroraQuestsView() }
            case .nova: NavigationStack { AuroraGuideView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            AuroraTabBar(tab: $tab)
        }
    }
}

// MARK: - Floating glass tab bar

private struct AuroraTabBar: View {
    @Binding var tab: AuroraTab

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AuroraTab.allCases, id: \.self) { item in
                Button {
                    Haptics.tap()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) {
                        tab = item
                    }
                } label: {
                    AuroraTabItem(item: item, isActive: tab == item)
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(6)
        .background(Color(hex: 0x101226).opacity(0.92), in: Capsule())
        .overlay(Capsule().strokeBorder(Color.white.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.5), radius: 20, y: 10)
        .padding(.horizontal, 24)
        .padding(.bottom, 6)
    }
}

private struct AuroraTabItem: View {
    let item: AuroraTab
    let isActive: Bool

    var body: some View {
        VStack(spacing: 3) {
            Image(systemName: item.symbol)
                .font(.system(size: 17, weight: .semibold))
                .shadow(color: isActive ? item.accent.opacity(0.9) : .clear, radius: 7)
            Text(item.title)
                .font(.system(.caption2, design: .rounded)
                    .weight(isActive ? .bold : .medium))
        }
        .foregroundStyle(isActive ? item.accent : Aurora.inkFaint)
        .padding(.vertical, 9)
        .frame(maxWidth: .infinity)
        .background {
            if isActive {
                Capsule().fill(item.accent.opacity(0.13))
            }
        }
        .contentShape(Capsule())
    }
}
