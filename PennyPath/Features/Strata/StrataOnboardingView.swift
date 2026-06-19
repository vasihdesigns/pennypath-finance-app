//
//  StrataOnboardingView.swift
//  PennyPath
//
//  Strata's own first-run tour (Developer Mode only). Four periwinkle pages
//  that show off the idea: net worth as clear layers, the big private number,
//  the growth trend, and on-device insights. Separate from the real app's
//  onboarding.
//

import SwiftUI

private enum StrataArt { case layers, worth, trend, insight }

private struct StrataPage: Identifiable {
    let id = UUID()
    let art: StrataArt
    let overline: String
    let title: String
    let message: String
}

struct StrataOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var started = false

    private let pages: [StrataPage] = [
        StrataPage(art: .layers, overline: "Welcome to Strata",
                   title: "Your wealth,\nin clear layers",
                   message: "The same PennyPath you know — focused on what you own and owe, broken into clean proportional layers."),
        StrataPage(art: .worth, overline: "One number",
                   title: "Net worth\nat a glance",
                   message: "Everything adds up to a single number — with a tap to hide it when you're not alone."),
        StrataPage(art: .trend, overline: "Trend",
                   title: "Watch your\nwealth grow",
                   message: "See your net worth climb over time, across a month, a year, or all of it."),
        StrataPage(art: .insight, overline: "Insights",
                   title: "Quiet, useful\nnudges",
                   message: "Friendly tips drawn from your own numbers — made right on your device, never sent anywhere.")
    ]

    private var lastIndex: Int { pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    StrataPageView(page: item, isActive: started && page == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            controls
        }
        .background(Strata.bg.ignoresSafeArea())
        .onAppear { started = true }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(Strata.onBrandSoft)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
        }
        .padding(.horizontal, 24).padding(.top, 12).frame(height: 40)
    }

    private var controls: some View {
        VStack(spacing: 22) {
            StrataDots(count: pages.count, index: page)
            Button {
                if page == lastIndex { finish() }
                else { Haptics.tap(); withAnimation(.easeInOut) { page += 1 } }
            } label: {
                Text(page == lastIndex ? "Get started" : "Continue")
                    .font(.system(.subheadline).weight(.bold))
                    .foregroundStyle(Strata.bg)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.white, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 40).padding(.top, 8)
    }

    private func finish() { Haptics.success(); onFinish() }
}

private struct StrataDots: View {
    let count: Int
    let index: Int
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Color.white : Color.white.opacity(0.35))
                    .frame(width: i == index ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

private struct StrataPageView: View {
    let page: StrataPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            StrataArtView(kind: page.art)
                .frame(height: 280)
                .scaleEffect(isActive ? 1 : 0.92)
                .opacity(isActive ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isActive)
            Spacer(minLength: 28)
            VStack(spacing: 12) {
                StrataOverline(text: page.overline, tint: .white)
                Text(page.title)
                    .font(.strataDisplay(30))
                    .foregroundStyle(Strata.onBrand)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(page.message)
                    .font(.system(.body))
                    .foregroundStyle(Strata.onBrandSoft)
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

private struct StrataArtView: View {
    let kind: StrataArt

    private let sampleBands: [StrataBand] = [
        StrataBand(color: Strata.property, label: "Property", value: 0, share: 0.40, isLiability: false),
        StrataBand(color: Strata.investment, label: "Investments", value: 0, share: 0.31, isLiability: false),
        StrataBand(color: Strata.cash, label: "Cash", value: 0, share: 0.22, isLiability: false),
        StrataBand(color: Strata.otherAsset, label: "Other", value: 0, share: 0.07, isLiability: false),
        StrataBand(color: Strata.creditCard, label: "Debt", value: 0, share: 0.18, isLiability: true)
    ]

    var body: some View {
        Group {
            switch kind {
            case .layers:
                StrataComposition(bands: sampleBands, assetsHeight: 150)
                    .frame(width: 220)
                    .strataCard(padding: 16)
            case .worth:
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        StrataOverline(text: "Net worth", tint: Strata.inkSoft)
                        Image(systemName: "eye.fill").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Strata.inkSoft)
                    }
                    Text(money(1_472_200)).font(.strataAmount(34, weight: .heavy))
                        .foregroundStyle(Strata.ink).minimumScaleFactor(0.5).lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .black))
                        Text("+\(money(18_293)) this month").font(.system(.caption).weight(.bold))
                    }
                    .foregroundStyle(Strata.cash)
                }
                .padding(20).frame(width: 280, alignment: .leading)
                .strataCard(padding: 20)
            case .trend:
                VStack(spacing: 10) {
                    Sparkline(values: [3, 3.4, 3.2, 4.1, 4.6, 4.4, 5.6, 6.8, 7.2, 9.0],
                              tint: Strata.investment, lineWidth: 3)
                        .frame(height: 120)
                    StrataOverline(text: "Up 38% this year", tint: Strata.cash)
                }
                .padding(20).frame(width: 280)
                .strataCard(padding: 20)
            case .insight:
                ZStack {
                    Circle().fill(.white).frame(width: 120, height: 120)
                        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(Strata.bg)
                }
            }
        }
    }
}
