//
//  OnboardingView.swift
//  PennyPath
//
//  A short, friendly first-run tour. Each page shows an animated mini-preview of
//  one pillar, in that pillar's color, so you know what the app does before you
//  even start. Clean black & white, with green / red / gold doing the talking.
//

import SwiftUI

// MARK: - Page model

private enum OnboardingArt {
    case logo, netWorth, spending, goals, coach
}

private struct OnboardingPage: Identifiable {
    let id = UUID()
    let art: OnboardingArt
    let accent: Color
    let neutral: Bool   // true for the black/white welcome page
    let title: String
    let message: String
}

// MARK: - Onboarding container

struct OnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var started = false

    private let pages: [OnboardingPage] = [
        OnboardingPage(art: .logo, accent: Theme.ink, neutral: true,
                       title: "Welcome to PennyPath",
                       message: "Your money, made simple — clear enough for anyone to understand."),
        OnboardingPage(art: .netWorth, accent: Theme.green, neutral: false,
                       title: "Know your true worth",
                       message: "Everything you own, minus everything you owe. One honest number, always up to date."),
        OnboardingPage(art: .spending, accent: Theme.red, neutral: false,
                       title: "See where it goes",
                       message: "Track your spending and catch the little leaks before they add up."),
        OnboardingPage(art: .goals, accent: Theme.gold, neutral: false,
                       title: "Save for what matters",
                       message: "Set a goal and watch the gold bar fill up as you get closer."),
        OnboardingPage(art: .coach, accent: Theme.gold, neutral: false,
                       title: "Your pocket money coach",
                       message: "Friendly tips made from your own numbers — right here on your device.")
    ]

    private var lastIndex: Int { pages.count - 1 }
    private var current: OnboardingPage { pages[page] }
    private var accent: Color { current.neutral ? Theme.ink : current.accent }

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        OnboardingPageView(page: item, isActive: started && page == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                controls
            }
        }
        .onAppear { started = true }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
        }
        .padding(.horizontal, Theme.Space.xl)
        .padding(.top, Theme.Space.sm)
        .frame(height: 36)
    }

    private var controls: some View {
        VStack(spacing: Theme.Space.xl) {
            PageDots(count: pages.count, index: page, accent: accent)
            Button(action: advance) {
                Text(page == lastIndex ? "Get Started" : "Continue")
            }
            .buttonStyle(PrimaryButtonStyle(
                tint: current.neutral ? Theme.ink : accent,
                foreground: current.neutral ? Color(.systemBackground) : .white))
            .padding(.horizontal, Theme.Space.xl)
        }
        .padding(.bottom, Theme.Space.xxl)
        .padding(.top, Theme.Space.sm)
    }

    private func advance() {
        if page == lastIndex {
            finish()
        } else {
            Haptics.tap()
            withAnimation(.easeInOut) { page += 1 }
        }
    }

    private func finish() {
        Haptics.success()
        onFinish()
    }
}

// MARK: - Page indicator

private struct PageDots: View {
    let count: Int
    let index: Int
    var accent: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? accent : Theme.hairline)
                    .frame(width: i == index ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

// MARK: - A single page

private struct OnboardingPageView: View {
    let page: OnboardingPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: Theme.Space.lg)
            OnboardingArtView(kind: page.art, accent: page.accent, isActive: isActive)
            Spacer(minLength: Theme.Space.xl)
            VStack(spacing: Theme.Space.md) {
                Text(page.title)
                    .font(.display(28))
                    .foregroundStyle(Theme.ink)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.body)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 14)
            .animation(.easeOut(duration: 0.45).delay(0.05), value: isActive)
            Spacer(minLength: Theme.Space.lg)
        }
        .padding(.horizontal, Theme.Space.xxl)
    }
}

// MARK: - Animated mini-previews (the "wow")

private struct OnboardingArtView: View {
    let kind: OnboardingArt
    let accent: Color
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.10))
                .frame(width: 250, height: 250)
                .scaleEffect(isActive ? 1 : 0.85)
                .opacity(isActive ? 1 : 0)
            content
                .frame(width: 290)
                .scaleEffect(isActive ? 1 : 0.92)
                .opacity(isActive ? 1 : 0)
        }
        .frame(height: 280)
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isActive)
    }

    @ViewBuilder private var content: some View {
        switch kind {
        case .logo: logo
        case .netWorth: netWorth
        case .spending: spending
        case .goals: goals
        case .coach: coach
        }
    }

    // The three growing pill-bars from the app icon.
    private var logo: some View {
        HStack(alignment: .bottom, spacing: 18) {
            bar(Theme.red, isActive ? 80 : 10)
            bar(Theme.gold, isActive ? 130 : 10)
            bar(Theme.green, isActive ? 178 : 10)
        }
    }

    private func bar(_ color: Color, _ height: CGFloat) -> some View {
        Capsule().fill(color).frame(width: 46, height: height)
    }

    private var netWorth: some View {
        previewCard {
            Text("NET WORTH").font(.caption.weight(.semibold)).foregroundStyle(Theme.inkSecondary).tracking(1)
            Text(money(12_450)).font(.amount(34)).foregroundStyle(Theme.green)
            SplitBar(leading: isActive ? 72 : 0.001, trailing: 28, height: 16)
            HStack {
                legendDot(Theme.green, "Own")
                Spacer()
                legendDot(Theme.red, "Owe")
            }
        }
    }

    private var spending: some View {
        previewCard {
            Text("THIS MONTH").font(.caption.weight(.semibold)).foregroundStyle(Theme.inkSecondary).tracking(1)
            Text(money(840)).font(.amount(30)).foregroundStyle(Theme.red)
            spendRow("🍔", isActive ? 0.95 : 0)
            spendRow("🚗", isActive ? 0.6 : 0)
            spendRow("🎮", isActive ? 0.35 : 0)
        }
    }

    private func spendRow(_ emoji: String, _ value: Double) -> some View {
        HStack(spacing: Theme.Space.sm) {
            Text(emoji)
            ProgressBar(value: value, tint: Theme.red, height: 8)
        }
    }

    private var goals: some View {
        previewCard {
            HStack(spacing: Theme.Space.lg) {
                ZStack {
                    ProgressRing(value: isActive ? 0.7 : 0, tint: Theme.gold, lineWidth: 11)
                    Text("70%").font(.amount(16)).foregroundStyle(Theme.ink)
                }
                .frame(width: 78, height: 78)
                VStack(alignment: .leading, spacing: 6) {
                    Text("New Bike 🚲").font(.headline).foregroundStyle(Theme.ink)
                    ProgressBar(value: isActive ? 0.7 : 0, tint: Theme.gold, height: 8)
                    Text("\(money(140)) to go").font(.caption).foregroundStyle(Theme.inkSecondary)
                }
            }
        }
    }

    private var coach: some View {
        previewCard {
            HStack(alignment: .top, spacing: Theme.Space.md) {
                EmojiBadge(emoji: "✨", tint: Theme.gold, size: 46)
                VStack(alignment: .leading, spacing: 4) {
                    Text("Spending is down").font(.headline).foregroundStyle(Theme.ink)
                    Text("You spent 33% less than last month — nice work!")
                        .font(.subheadline).foregroundStyle(Theme.inkSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .overlay(alignment: .leading) {
                Capsule().fill(Theme.gold).frame(width: 4).padding(.vertical, 2)
            }
        }
    }

    private func legendDot(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.caption).foregroundStyle(Theme.inkSecondary)
        }
    }

    private func previewCard<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: Theme.Space.md, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Space.lg)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
            .shadow(color: .black.opacity(0.07), radius: 18, x: 0, y: 10)
    }
}
