//
//  VividRootView.swift
//  PennyPath
//
//  The root of the "Vivid" reskin (Developer Mode only): four tabs —
//  Home, Spend, Goals, Coach — under a floating bar with a raised violet
//  "+" in the middle for the app's most-used action (add an expense).
//  Brings its own first-run intro, replayable, and never touches the real
//  app's onboarding flag.
//

import SwiftUI

enum VividTab: Hashable, CaseIterable {
    case home, spend, goals, coach

    var title: String {
        switch self {
        case .home: return "Home"
        case .spend: return "Spend"
        case .goals: return "Goals"
        case .coach: return "Coach"
        }
    }

    var symbol: String {
        switch self {
        case .home: return "house.fill"
        case .spend: return "creditcard.fill"
        case .goals: return "target"
        case .coach: return "sparkles"
        }
    }
}

struct VividRootView: View {
    @State private var tab: VividTab = .home
    @State private var showingAdd = false
    // Vivid keeps its own first-run flag so the real app's onboarding
    // (didCompleteOnboarding) is never touched.
    @AppStorage("vividDidOnboard") private var didOnboard = false

    var body: some View {
        ZStack {
            if didOnboard {
                shell.transition(.opacity)
            } else {
                VividOnboardingView {
                    withAnimation(.easeInOut(duration: 0.5)) { didOnboard = true }
                }
                .transition(.opacity)
            }
        }
    }

    private var shell: some View {
        Group {
            switch tab {
            case .home: NavigationStack { VividHomeView() }
            case .spend: NavigationStack { VividSpendView() }
            case .goals: NavigationStack { VividGoalsView() }
            case .coach: NavigationStack { VividCoachView() }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            VividTabBar(tab: $tab) { showingAdd = true }
        }
        // The center "+" adds an expense — the single most-used action.
        .sheet(isPresented: $showingAdd) { ExpenseFormView() }
    }
}

// MARK: - Floating tab bar with a center FAB

private struct VividTabBar: View {
    @Binding var tab: VividTab
    var onAdd: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            tabButton(.home)
            tabButton(.spend)
            fab
            tabButton(.goals)
            tabButton(.coach)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            Capsule()
                .fill(Vivid.card)
                .shadow(color: .black.opacity(0.16), radius: 22, y: 10)
        )
        .overlay(Capsule().strokeBorder(Vivid.hairline, lineWidth: 1))
        .padding(.horizontal, 20)
        .padding(.bottom, 4)
    }

    private func tabButton(_ item: VividTab) -> some View {
        Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.32, dampingFraction: 0.8)) { tab = item }
        } label: {
            VStack(spacing: 3) {
                Image(systemName: item.symbol)
                    .font(.system(size: 18, weight: .semibold))
                Text(item.title)
                    .font(.system(.caption2, design: .rounded)
                        .weight(tab == item ? .bold : .medium))
            }
            .foregroundStyle(tab == item ? Vivid.violet : Vivid.inkFaint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    /// The raised violet add button at the center of the bar.
    private var fab: some View {
        Button {
            Haptics.tap(.medium)
            onAdd()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 54, height: 54)
                .background(Vivid.brandGradient, in: Circle())
                .overlay(Circle().strokeBorder(Vivid.bg, lineWidth: 4))
                .shadow(color: Vivid.violet.opacity(0.5), radius: 12, y: 5)
        }
        .buttonStyle(.plain)
        .frame(width: 64)
        .offset(y: -14)
        .accessibilityLabel("Add expense")
    }
}
