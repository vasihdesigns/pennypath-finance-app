//
//  AuroraOnboardingView.swift
//  PennyPath
//
//  Aurora's own first-run tour (Developer Mode only). Five night-sky
//  pages, each with a small animated scene: the rising orbs, a worth
//  constellation, a spending comet, a quest planet, and Nova the guide.
//  Completely separate from the real app's onboarding.
//

import SwiftUI

// MARK: - Page model

private enum AuroraArt {
    case orbs, constellation, comet, quest, nova
}

private struct AuroraPage: Identifiable {
    let id = UUID()
    let art: AuroraArt
    let accent: Color
    let overline: String
    let title: String
    let message: String
}

// MARK: - Container

struct AuroraOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var started = false

    private let pages: [AuroraPage] = [
        AuroraPage(art: .orbs, accent: Aurora.mint,
                   overline: "Welcome to Aurora",
                   title: "Money,\nunder night sky",
                   message: "The same PennyPath you know — reimagined as a calm little universe that's all yours."),
        AuroraPage(art: .constellation, accent: Aurora.mint,
                   overline: "Pulse",
                   title: "Your worth is\na constellation",
                   message: "Everything you own and owe, joined into one bright number that grows as you do."),
        AuroraPage(art: .comet, accent: Aurora.pink,
                   overline: "Flow",
                   title: "Watch where\nyour money flows",
                   message: "Every expense leaves a trail. Follow it, and the little leaks have nowhere to hide."),
        AuroraPage(art: .quest, accent: Aurora.gold,
                   overline: "Quests",
                   title: "Saving becomes\na quest",
                   message: "Pick something worth reaching for and watch its ring close, orbit by orbit."),
        AuroraPage(art: .nova, accent: Aurora.violet,
                   overline: "Nova",
                   title: "Meet Nova,\nyour guide",
                   message: "Friendly tips drawn from your own numbers — made on your device, never sent anywhere.")
    ]

    private var lastIndex: Int { pages.count - 1 }
    private var accent: Color { pages[page].accent }

    var body: some View {
        ZStack {
            AuroraSky()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        AuroraPageView(page: item, isActive: started && page == index)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                controls
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { started = true }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Aurora.inkSoft)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
        }
        .padding(.horizontal, 28)
        .padding(.top, 10)
        .frame(height: 40)
    }

    private var controls: some View {
        VStack(spacing: 24) {
            AuroraPageDots(count: pages.count, index: page, accent: accent)
            AuroraBeamButton(title: page == lastIndex ? "Enter Aurora" : "Continue") {
                advance()
            }
        }
        .padding(.bottom, 36)
        .padding(.top, 10)
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

private struct AuroraPageDots: View {
    let count: Int
    let index: Int
    var accent: Color

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? accent : Color.white.opacity(0.16))
                    .frame(width: i == index ? 24 : 7, height: 7)
                    .shadow(color: i == index ? accent.opacity(0.7) : .clear, radius: 6)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

// MARK: - A single page

private struct AuroraPageView: View {
    let page: AuroraPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            AuroraArtView(kind: page.art, accent: page.accent, isActive: isActive)
            Spacer(minLength: 28)
            VStack(spacing: 14) {
                AuroraOverline(text: page.overline, tint: page.accent)
                Text(page.title)
                    .font(.auroraDisplay(32))
                    .foregroundStyle(Aurora.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(page.message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Aurora.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 16)
            .animation(.easeOut(duration: 0.45).delay(0.05), value: isActive)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 34)
    }
}

// MARK: - Animated scenes

private struct AuroraArtView: View {
    let kind: AuroraArt
    let accent: Color
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(accent.opacity(0.12))
                .frame(width: 252, height: 252)
                .blur(radius: 30)
            Circle()
                .strokeBorder(accent.opacity(0.25), lineWidth: 1)
                .frame(width: 252, height: 252)
            content
        }
        .frame(height: 280)
        .scaleEffect(isActive ? 1 : 0.9)
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isActive)
    }

    @ViewBuilder private var content: some View {
        switch kind {
        case .orbs: orbs
        case .constellation: constellation
        case .comet: comet
        case .quest: quest
        case .nova: nova
        }
    }

    /// Three glowing orbs rising like the app icon's bars, reborn as planets.
    private var orbs: some View {
        HStack(alignment: .bottom, spacing: 26) {
            orb(Aurora.pink, size: 38, lift: isActive ? 26 : 0)
            orb(Aurora.gold, size: 52, lift: isActive ? 64 : 0)
            orb(Aurora.mint, size: 68, lift: isActive ? 108 : 0)
        }
        .frame(height: 190, alignment: .bottom)
    }

    private func orb(_ color: Color, size: CGFloat, lift: CGFloat) -> some View {
        Circle()
            .fill(
                RadialGradient(colors: [color, color.opacity(0.45)],
                               center: .init(x: 0.35, y: 0.3),
                               startRadius: 2, endRadius: size * 0.8)
            )
            .frame(width: size, height: size)
            .shadow(color: color.opacity(0.65), radius: 16)
            .offset(y: -lift)
            .animation(.spring(response: 0.9, dampingFraction: 0.65), value: lift)
    }

    /// Five stars joined into a rising constellation line.
    private var constellation: some View {
        let points: [CGPoint] = [
            .init(x: 22, y: 150), .init(x: 75, y: 110), .init(x: 120, y: 128),
            .init(x: 170, y: 64), .init(x: 218, y: 36)
        ]
        return ZStack {
            // The joining line, drawn point to point.
            Path { path in
                path.move(to: points[0])
                for p in points.dropFirst() { path.addLine(to: p) }
            }
            .trim(from: 0, to: isActive ? 1 : 0)
            .stroke(accent.opacity(0.7),
                    style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .animation(.easeInOut(duration: 1.1).delay(0.2), value: isActive)

            ForEach(Array(points.enumerated()), id: \.offset) { index, p in
                Circle()
                    .fill(.white)
                    .frame(width: index == points.count - 1 ? 11 : 7)
                    .shadow(color: accent, radius: 7)
                    .position(p)
                    .scaleEffect(isActive ? 1 : 0.01)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6)
                        .delay(0.15 + Double(index) * 0.12), value: isActive)
            }

            Text(money(12_450))
                .font(.auroraAmount(26))
                .foregroundStyle(Aurora.ink)
                .position(x: 120, y: 196)
                .opacity(isActive ? 1 : 0)
                .animation(.easeOut(duration: 0.5).delay(1.0), value: isActive)
        }
        .frame(width: 240, height: 220)
    }

    /// A comet sweeping down-left, shedding little expense sparks.
    private var comet: some View {
        ZStack {
            // The tail.
            Capsule()
                .fill(
                    LinearGradient(colors: [accent.opacity(0), accent.opacity(0.75)],
                                   startPoint: .topTrailing, endPoint: .bottomLeading)
                )
                .frame(width: isActive ? 170 : 30, height: 7)
                .rotationEffect(.degrees(-32))
                .offset(x: 18, y: -18)

            // The head.
            Circle()
                .fill(.white)
                .frame(width: 20)
                .shadow(color: accent, radius: 14)
                .offset(x: isActive ? -58 : 60, y: isActive ? 28 : -64)

            // Sparks it sheds — the day's little expenses.
            ForEach(0..<3, id: \.self) { i in
                let emoji = ["🍔", "🚗", "🎮"][i]
                Text(emoji)
                    .font(.system(size: 24))
                    .offset(x: [-10, 52, 96][i], y: [86, 44, -6][i])
                    .opacity(isActive ? 1 : 0)
                    .scaleEffect(isActive ? 1 : 0.3)
                    .animation(.spring(response: 0.5, dampingFraction: 0.6)
                        .delay(0.5 + Double(i) * 0.15), value: isActive)
            }
        }
        .animation(.easeOut(duration: 0.9).delay(0.15), value: isActive)
    }

    /// A planet whose golden ring closes as the goal fills up.
    private var quest: some View {
        ZStack {
            Circle()
                .stroke(Color.white.opacity(0.12), lineWidth: 10)
                .frame(width: 150, height: 150)
            Circle()
                .trim(from: 0, to: isActive ? 0.7 : 0.02)
                .stroke(accent, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 150, height: 150)
                .shadow(color: accent.opacity(0.6), radius: 10)
                .animation(.easeInOut(duration: 1.2).delay(0.25), value: isActive)

            VStack(spacing: 2) {
                Text("🚲").font(.system(size: 40))
                Text("70%")
                    .font(.auroraAmount(17))
                    .foregroundStyle(Aurora.ink)
            }

            // A little moon riding the ring's leading edge.
            Circle()
                .fill(.white)
                .frame(width: 13)
                .shadow(color: accent, radius: 6)
                .offset(y: -75)
                .rotationEffect(.degrees(isActive ? 0.7 * 360 : 7))
                .animation(.easeInOut(duration: 1.2).delay(0.25), value: isActive)
        }
    }

    /// Nova: a breathing violet-mint orb ringed by sparkles.
    private var nova: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(colors: [Aurora.mint.opacity(0.9), accent],
                                   center: .init(x: 0.35, y: 0.3),
                                   startRadius: 4, endRadius: 70)
                )
                .frame(width: 104, height: 104)
                .shadow(color: accent.opacity(0.8), radius: isActive ? 30 : 10)
                .scaleEffect(isActive ? 1.06 : 0.9)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true)
                    .delay(0.3), value: isActive)

            ForEach(0..<5, id: \.self) { i in
                Image(systemName: "sparkle")
                    .font(.system(size: [10, 15, 9, 13, 11][i]))
                    .foregroundStyle(.white.opacity(0.9))
                    .offset(x: [-86, 74, 96, -60, 12][i], y: [-50, -72, 22, 66, -104][i])
                    .opacity(isActive ? 1 : 0)
                    .scaleEffect(isActive ? 1 : 0.2)
                    .animation(.spring(response: 0.6, dampingFraction: 0.6)
                        .delay(0.3 + Double(i) * 0.12), value: isActive)
            }
        }
    }
}
