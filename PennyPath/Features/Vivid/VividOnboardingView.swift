//
//  VividOnboardingView.swift
//  PennyPath
//
//  Vivid's own first-run tour (Developer Mode only). Four bright pages that
//  show off the look — the hero number, the spending donut, a goal ring, and
//  the coach. Completely separate from the real app's onboarding.
//

import SwiftUI

private enum VividArt { case hero, donut, ring, spark }

private struct VividPage: Identifiable {
    let id = UUID()
    let art: VividArt
    let overline: String
    let title: String
    let message: String
}

struct VividOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var started = false

    private let pages: [VividPage] = [
        VividPage(art: .hero, overline: "Welcome to Vivid",
                  title: "Your money,\nmade vivid",
                  message: "The same PennyPath you know — with the numbers that matter turned up loud and bright."),
        VividPage(art: .donut, overline: "Spend",
                  title: "See exactly\nwhere it goes",
                  message: "Every month rolls up into one clear picture, so the little leaks have nowhere to hide."),
        VividPage(art: .ring, overline: "Goals",
                  title: "Watch your\ndreams fill up",
                  message: "Pick something worth saving for and watch its ring close, one contribution at a time."),
        VividPage(art: .spark, overline: "Coach",
                  title: "Tips made\njust for you",
                  message: "Friendly advice drawn from your own numbers — made right on your device, never sent anywhere.")
    ]

    private var lastIndex: Int { pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar

            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    VividPageView(page: item, isActive: started && page == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))

            controls
        }
        .background(Vivid.bg.ignoresSafeArea())
        .onAppear { started = true }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .font(.system(.subheadline, design: .rounded).weight(.semibold))
                .foregroundStyle(Vivid.inkSoft)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
        }
        .padding(.horizontal, 24)
        .padding(.top, 12)
        .frame(height: 40)
    }

    private var controls: some View {
        VStack(spacing: 24) {
            VividPageDots(count: pages.count, index: page)
            VividPrimaryButton(title: page == lastIndex ? "Get started" : "Continue") {
                advance()
            }
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

private struct VividPageDots: View {
    let count: Int
    let index: Int

    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? AnyShapeStyle(Vivid.brandGradient)
                                     : AnyShapeStyle(Vivid.well))
                    .frame(width: i == index ? 24 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

// MARK: - A single page

private struct VividPageView: View {
    let page: VividPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            VividArtView(kind: page.art, isActive: isActive)
                .frame(height: 260)
            Spacer(minLength: 28)
            VStack(spacing: 14) {
                VividOverline(text: page.overline, tint: Vivid.violet)
                Text(page.title)
                    .font(.vividDisplay(32))
                    .foregroundStyle(Vivid.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(page.message)
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(Vivid.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 16)
            .animation(.easeOut(duration: 0.45).delay(0.05), value: isActive)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 32)
    }
}

// MARK: - Art

private struct VividArtView: View {
    let kind: VividArt
    let isActive: Bool

    var body: some View {
        ZStack {
            Circle()
                .fill(Vivid.violet.opacity(0.10))
                .frame(width: 240, height: 240)
                .blur(radius: 24)
            content
        }
        .scaleEffect(isActive ? 1 : 0.9)
        .opacity(isActive ? 1 : 0)
        .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isActive)
    }

    @ViewBuilder private var content: some View {
        switch kind {
        case .hero: heroCard
        case .donut: donut
        case .ring: ring
        case .spark: spark
        }
    }

    /// A miniature of the net-worth hero card.
    private var heroCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            VividOverline(text: "Net worth", tint: .white.opacity(0.85))
            VividAmount(value: 22_677.45, size: 40, tint: .white, trimOpacity: 0.7)
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .black))
                Text("+\(money(1240)) this month")
                    .font(.system(.caption, design: .rounded).weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 5).padding(.horizontal, 11)
            .background(.white.opacity(0.18), in: Capsule())
        }
        .padding(22)
        .frame(width: 280, alignment: .leading)
        .background(Vivid.brandGradient,
                    in: RoundedRectangle(cornerRadius: 26, style: .continuous))
        .shadow(color: Vivid.violet.opacity(0.4), radius: 22, y: 12)
        .rotationEffect(.degrees(-4))
    }

    private var donut: some View {
        VividDonut(progress: isActive ? 0.68 : 0.0, lineWidth: 26) {
            VStack(spacing: 2) {
                VividOverline(text: "Spent")
                VividAmount(value: 1_284, size: 30)
            }
        }
        .frame(width: 190, height: 190)
    }

    private var ring: some View {
        VividDonut(progress: isActive ? 0.7 : 0.0, lineWidth: 22) {
            Text("🚲").font(.system(size: 54))
        }
        .frame(width: 190, height: 190)
    }

    private var spark: some View {
        ZStack {
            Circle()
                .fill(Vivid.brandGradient)
                .frame(width: 120, height: 120)
                .shadow(color: Vivid.violet.opacity(0.5), radius: 24)
                .scaleEffect(isActive ? 1.04 : 0.92)
                .animation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true), value: isActive)
            Image(systemName: "sparkles")
                .font(.system(size: 48, weight: .bold))
                .foregroundStyle(.white)
        }
    }
}
