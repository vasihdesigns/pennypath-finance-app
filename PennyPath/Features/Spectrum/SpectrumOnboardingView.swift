//
//  SpectrumOnboardingView.swift
//  PennyPath
//
//  The first-run welcome for the shipping Spectrum app. Five pages, each with an
//  animated mini-preview built from the real Spectrum vocabulary — the fanned
//  jewel-tone card deck, a live net-worth split, budget burn bars, a goal dial
//  with milestone medals, and an insight card. On-brand, calm, and a little
//  delightful. Gated by `didCompleteOnboarding`; the Developer "Replay
//  onboarding" button re-shows it.
//

import SwiftUI

// MARK: - Page model

private enum SpectrumOnboardArt { case deck, netWorth, expenses, goals, insights }

private struct SpectrumOnboardPage: Identifiable {
    let id = UUID()
    let art: SpectrumOnboardArt
    let accent: Color
    let title: String
    let message: String
}

// MARK: - Container

struct SpectrumOnboardingView: View {
    var onFinish: () -> Void

    @Environment(\.colorScheme) private var scheme
    @State private var page = 0
    @State private var started = false

    private let pages: [SpectrumOnboardPage] = [
        .init(art: .deck, accent: Spectrum.accentSoft,
              title: "Welcome to PennyPath",
              message: "Your whole financial world — in one calm, colourful place."),
        .init(art: .netWorth, accent: Spectrum.good,
              title: "One honest number",
              message: "Everything you own and owe, added into your true net worth — and it updates live."),
        .init(art: .expenses, accent: Color(hex: 0x8C5622),
              title: "See where it goes",
              message: "Each budget fills and shifts colour as you spend, so nothing sneaks up on you."),
        .init(art: .goals, accent: Color(hex: 0x614674),
              title: "Celebrate every win",
              message: "Watch goals fill up and net-worth milestones light up as you climb."),
        .init(art: .insights, accent: Spectrum.accentSoft,
              title: "Tips made just for you",
              message: "Quiet, private insights drawn from your own numbers — never leaving your device.")
    ]

    private var lastIndex: Int { pages.count - 1 }
    private var current: SpectrumOnboardPage { pages[page] }

    var body: some View {
        ZStack {
            Spectrum.canvas.ignoresSafeArea()
            backdrop
            VStack(spacing: 0) {
                topBar
                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        SpectrumOnboardPageView(page: item, isActive: started && page == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                controls
            }
        }
        .onAppear { started = true }
    }

    /// Two soft, blurred jewel-tone blobs tinted by the current page — gives the
    /// flat canvas depth and shifts hue as you move through the tour.
    private var backdrop: some View {
        ZStack {
            Circle().fill(current.accent.opacity(scheme == .dark ? 0.30 : 0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(x: -120, y: -220)
            Circle().fill(current.accent.opacity(scheme == .dark ? 0.22 : 0.12))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: 140, y: 180)
        }
        .animation(.easeInOut(duration: 0.6), value: page)
        .allowsHitTesting(false)
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
                .accessibilityHidden(page == lastIndex)
        }
        .padding(.horizontal, 24)
        .padding(.top, 8)
        .frame(height: 40)
    }

    private var controls: some View {
        VStack(spacing: 22) {
            SpectrumPageDots(count: pages.count, index: page, accent: current.accent)
            Button(action: advance) {
                Text(page == lastIndex ? "Get Started" : "Continue")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Spectrum.plusInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Spectrum.plus, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 24)
        }
        .padding(.bottom, 40)
        .padding(.top, 8)
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

// MARK: - Page dots

private struct SpectrumPageDots: View {
    let count: Int
    let index: Int
    var accent: Color

    var body: some View {
        HStack(spacing: 6) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? accent : Spectrum.onCanvasSoft.opacity(0.3))
                    .frame(width: i == index ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

// MARK: - A single page

private struct SpectrumOnboardPageView: View {
    let page: SpectrumOnboardPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            SpectrumOnboardArtView(kind: page.art, accent: page.accent, isActive: isActive)
                .frame(height: 300)
            Spacer(minLength: 24)
            VStack(spacing: 12) {
                Text(page.title)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundStyle(Spectrum.onCanvas)
                    .multilineTextAlignment(.center)
                Text(page.message)
                    .font(.system(size: 16))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 14)
            .animation(.easeOut(duration: 0.45).delay(0.05), value: isActive)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Animated mini-previews

private struct SpectrumOnboardArtView: View {
    let kind: SpectrumOnboardArt
    let accent: Color
    let isActive: Bool

    var body: some View {
        Group {
            switch kind {
            case .deck:      deck
            case .netWorth:  netWorth
            case .expenses:  expenses
            case .goals:     goals
            case .insights:  insights
            }
        }
        .scaleEffect(isActive ? 1 : 0.92)
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isActive)
    }

    // MARK: Deck — the signature fanned hand of jewel-tone cards

    private var deck: some View {
        let specs: [(SpectrumMoneyKind, String, String)] = [
            (.cash, "Cash", "$8.2k"),
            (.investment, "Investments", "$20.8k"),
            (.property, "Property", "$11k"),
            (.liability, "Cards", "−$6.3k"),
        ]
        let n = specs.count
        return ZStack {
            ForEach(Array(specs.enumerated()), id: \.offset) { i, s in
                let t = Double(i) - Double(n - 1) / 2     // −1.5 … 1.5
                deckCard(s.0, title: s.1, amount: s.2)
                    .rotationEffect(.degrees(isActive ? t * 9 : 0))
                    .offset(x: isActive ? t * 40 : 0,
                            y: isActive ? abs(t) * 12 : 0)
                    .zIndex(Double(i))
                    .animation(.spring(response: 0.7, dampingFraction: 0.8)
                        .delay(Double(i) * 0.06), value: isActive)
            }
        }
    }

    private func deckCard(_ kind: SpectrumMoneyKind, title: String, amount: String) -> some View {
        RoundedRectangle(cornerRadius: 22, style: .continuous)
            .fill(LinearGradient(colors: [kind.fill, kind.fillBottom],
                                 startPoint: .top, endPoint: .bottom))
            .frame(width: 152, height: 100)
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 0) {
                    Image(systemName: kind.symbol)
                        .font(.system(size: 15, weight: .semibold))
                    Spacer(minLength: 8)
                    Text(title)
                        .font(.system(size: 12, weight: .semibold))
                        .opacity(0.85)
                    Text(amount)
                        .font(.system(size: 19, weight: .bold))
                }
                .foregroundStyle(.white)
                .padding(14)
            }
            .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(.white.opacity(0.18), lineWidth: 1))
            .shadow(color: .black.opacity(0.28), radius: 12, y: 7)
    }

    // MARK: Net Worth — one number + an assets/liabilities split

    private var netWorth: some View {
        panel {
            Text("NET WORTH")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundStyle(Spectrum.onCanvasSoft)
            Text(money(36_568))
                .font(.system(size: 38, weight: .bold))
                .foregroundStyle(Spectrum.onCanvas)
            GeometryReader { geo in
                HStack(spacing: 4) {
                    Capsule().fill(Spectrum.good)
                        .frame(width: isActive ? geo.size.width * 0.82 : 0)
                    Capsule().fill(Spectrum.spend)
                }
            }
            .frame(height: 16)
            .animation(.spring(response: 0.7, dampingFraction: 0.85), value: isActive)
            HStack {
                legend(Spectrum.good, "Assets")
                Spacer()
                legend(Spectrum.spend, "Debts")
            }
        }
    }

    // MARK: Expenses — budget burn bars filling

    private var expenses: some View {
        panel {
            Text("THIS MONTH")
                .font(.system(size: 11, weight: .semibold)).tracking(1)
                .foregroundStyle(Spectrum.onCanvasSoft)
            burnBar("🍔", "Food", Spectrum.categoryColor(.food), isActive ? 0.92 : 0)
            burnBar("🚗", "Transport", Spectrum.categoryColor(.transport), isActive ? 0.55 : 0)
            burnBar("🎮", "Fun", Spectrum.categoryColor(.fun), isActive ? 0.32 : 0)
        }
    }

    private func burnBar(_ emoji: String, _ title: String, _ color: Color, _ fill: Double) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(color.opacity(0.20))
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .fill(color.gradient)
                    .frame(width: max(0, fill) * geo.size.width)
                HStack(spacing: 8) {
                    Text(emoji).font(.system(size: 14))
                    Text(title)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, 12)
            }
        }
        .frame(height: 34)
        .animation(.spring(response: 0.7, dampingFraction: 0.85), value: fill)
    }

    // MARK: Goals — a progress dial flanked by milestone medals

    private var goals: some View {
        panel {
            HStack(spacing: 16) {
                ZStack {
                    Circle().stroke(Spectrum.onCanvasSoft.opacity(0.18), lineWidth: 9)
                    Circle().trim(from: 0, to: isActive ? 0.7 : 0)
                        .stroke(accent, style: StrokeStyle(lineWidth: 9, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("🚲").font(.system(size: 24))
                }
                .frame(width: 74, height: 74)
                .animation(.spring(response: 0.8, dampingFraction: 0.85), value: isActive)
                VStack(alignment: .leading, spacing: 8) {
                    Text("New Bike")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Spectrum.onCanvas)
                    HStack(spacing: 6) {
                        ForEach(0..<3, id: \.self) { i in
                            medal(reached: i < 2, delay: Double(i) * 0.1)
                        }
                    }
                    Text("$140 to go")
                        .font(.system(size: 12.5, weight: .medium))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
            }
        }
    }

    /// A small milestone medal — deep teal so the white check reads in both modes.
    private func medal(reached: Bool, delay: Double) -> some View {
        ZStack {
            Circle()
                .fill(reached ? Color(hex: 0x1E6B5B) : Spectrum.onCanvasSoft.opacity(0.18))
                .frame(width: 24, height: 24)
            Image(systemName: reached ? "checkmark" : "lock.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(reached ? .white : Spectrum.onCanvasSoft)
        }
        .scaleEffect(isActive ? 1 : 0.4)
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.2 + delay), value: isActive)
    }

    // MARK: Insights — a glowing tip card

    private var insights: some View {
        panel {
            HStack(alignment: .top, spacing: 14) {
                ZStack {
                    Circle().fill(accent.opacity(0.18)).frame(width: 48, height: 48)
                    Image(systemName: "sparkles")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(accent)
                }
                VStack(alignment: .leading, spacing: 5) {
                    Text("Spending is down")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Spectrum.onCanvas)
                    Text("You spent 18% less than last month — nice work.")
                        .font(.system(size: 13))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .overlay(alignment: .leading) {
                Capsule().fill(accent).frame(width: 4)
                    .padding(.vertical, 2).offset(x: -14)
            }
        }
    }

    // MARK: Shared pieces

    private func legend(_ color: Color, _ label: String) -> some View {
        HStack(spacing: 6) {
            Circle().fill(color).frame(width: 9, height: 9)
            Text(label).font(.system(size: 12)).foregroundStyle(Spectrum.onCanvasSoft)
        }
    }

    private func panel<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 14, content: content)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(width: 300)
            .padding(20)
            .background(SpectrumGlass())
    }
}

/// The neutral translucent panel used by the onboarding previews — matches the
/// Spectrum content cards (faint fill + hairline rim, adaptive light/dark).
private struct SpectrumGlass: View {
    @Environment(\.colorScheme) private var scheme
    var body: some View {
        RoundedRectangle(cornerRadius: 26, style: .continuous)
            .fill(Spectrum.glassFill(dark: scheme == .dark))
            .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous)
                .strokeBorder(Spectrum.glassStroke(dark: scheme == .dark), lineWidth: 1))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 10)
    }
}
