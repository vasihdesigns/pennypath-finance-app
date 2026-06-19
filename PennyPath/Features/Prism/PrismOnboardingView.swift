//
//  PrismOnboardingView.swift
//  PennyPath
//
//  Prism's own first-run tour (Developer Mode only). Four pages on the flat
//  canvas that show off the idea: every money kind as its own coloured box,
//  the big private net-worth number, spending by colour, and on-device
//  insights. Separate from the real app's onboarding.
//

import SwiftUI

private enum PrismArt { case boxes, worth, spend, insight }

private struct PrismPage: Identifiable {
    let id = UUID()
    let art: PrismArt
    let overline: String
    let title: String
    let message: String
}

struct PrismOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var started = false

    private let pages: [PrismPage] = [
        PrismPage(art: .boxes, overline: "Welcome to Prism",
                  title: "Every kind of money,\nits own colour",
                  message: "The same PennyPath you know — with each account type shown as its own calm, coloured card."),
        PrismPage(art: .worth, overline: "One number",
                  title: "Net worth\nat a glance",
                  message: "Everything adds up to a single number — with a tap to hide it when you're not alone."),
        PrismPage(art: .spend, overline: "Spending",
                  title: "See where\nit goes",
                  message: "Your month's spending breaks down by category, each in its own colour, so patterns jump out."),
        PrismPage(art: .insight, overline: "Insights",
                  title: "Quiet, useful\nnudges",
                  message: "Friendly tips drawn from your own numbers — made right on your device, never sent anywhere.")
    ]

    private var lastIndex: Int { pages.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            topBar
            TabView(selection: $page) {
                ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                    PrismPageView(page: item, isActive: started && page == index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            controls
        }
        .background(Prism.bg.ignoresSafeArea())
        .onAppear { started = true }
    }

    private var topBar: some View {
        HStack {
            Spacer()
            Button("Skip") { finish() }
                .font(.system(.subheadline).weight(.semibold))
                .foregroundStyle(Prism.inkSoft)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
        }
        .padding(.horizontal, 24).padding(.top, 12).frame(height: 40)
    }

    private var controls: some View {
        VStack(spacing: 22) {
            PrismDots(count: pages.count, index: page)
            Button {
                if page == lastIndex { finish() }
                else { Haptics.tap(); withAnimation(.easeInOut) { page += 1 } }
            } label: {
                Text(page == lastIndex ? "Get started" : "Continue")
                    .font(.system(.subheadline).weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Prism.accent, in: Capsule())
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 40)
        }
        .padding(.bottom, 40).padding(.top, 8)
    }

    private func finish() { Haptics.success(); onFinish() }
}

private struct PrismDots: View {
    let count: Int
    let index: Int
    var body: some View {
        HStack(spacing: 7) {
            ForEach(0..<count, id: \.self) { i in
                Capsule()
                    .fill(i == index ? Prism.accent : Prism.inkFaint.opacity(0.5))
                    .frame(width: i == index ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
    }
}

private struct PrismPageView: View {
    let page: PrismPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            PrismArtView(kind: page.art)
                .frame(height: 280)
                .scaleEffect(isActive ? 1 : 0.92)
                .opacity(isActive ? 1 : 0)
                .animation(.spring(response: 0.6, dampingFraction: 0.82), value: isActive)
            Spacer(minLength: 28)
            VStack(spacing: 12) {
                PrismOverline(text: page.overline, tint: Prism.accent)
                Text(page.title)
                    .font(.prismDisplay(30))
                    .foregroundStyle(Prism.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(page.message)
                    .font(.system(.body))
                    .foregroundStyle(Prism.inkSoft)
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

private struct PrismArtView: View {
    let kind: PrismArt

    private let spendColumns = [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)]

    var body: some View {
        Group {
            switch kind {
            case .boxes:
                VStack(spacing: 10) {
                    miniBox(.cash, title: "Cash", amount: "12,400")
                    miniBox(.investment, title: "Investments", amount: "38,250")
                    miniBox(.property, title: "Property", amount: "210,000")
                }
                .frame(width: 256)
            case .worth:
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        PrismOverline(text: "Net worth")
                        Image(systemName: "eye.fill").font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(Prism.inkSoft)
                    }
                    Text(money(260_650)).font(.prismAmount(34, weight: .heavy))
                        .foregroundStyle(Prism.ink).minimumScaleFactor(0.5).lineLimit(1)
                    HStack(spacing: 4) {
                        Image(systemName: "arrow.up.right").font(.system(size: 9, weight: .black))
                        Text("+\(money(4_120)) this month").font(.system(.caption).weight(.bold))
                    }
                    .foregroundStyle(Prism.accent)
                }
                .frame(width: 280, alignment: .leading)
                .prismSurfaceCard(padding: 22)
            case .spend:
                LazyVGrid(columns: spendColumns, spacing: 10) {
                    spendTile(0, emoji: "🍔", amount: "320")
                    spendTile(1, emoji: "🚕", amount: "180")
                    spendTile(2, emoji: "🛍️", amount: "240")
                    spendTile(3, emoji: "🎬", amount: "90")
                }
                .frame(width: 256)
            case .insight:
                ZStack {
                    Circle().fill(Prism.accent).frame(width: 120, height: 120)
                        .shadow(color: Prism.accent.opacity(0.4), radius: 16, y: 6)
                    Image(systemName: "sparkles")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundStyle(.white)
                }
            }
        }
    }

    private func miniBox(_ category: AccountCategory, title: String, amount: String) -> some View {
        HStack(spacing: 12) {
            Text(category.emoji)
                .font(.system(size: 16))
                .frame(width: 36, height: 36)
                .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            Text(title).font(.system(.subheadline).weight(.bold)).foregroundStyle(.white)
            Spacer(minLength: 8)
            Text(money(Double(amount.replacingOccurrences(of: ",", with: "")) ?? 0))
                .font(.prismAmount(15, weight: .bold)).foregroundStyle(.white)
        }
        .prismGradientCard(Prism.gradient(for: category), padding: 13)
    }

    private func spendTile(_ index: Int, emoji: String, amount: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(emoji).font(.system(size: 18))
            Text(money(Double(amount) ?? 0))
                .font(.prismAmount(16, weight: .bold)).foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .prismGradientCard(Prism.chartGradient(index), padding: 14)
    }
}
