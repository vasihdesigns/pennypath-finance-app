//
//  ClarityOnboardingView.swift
//  PennyPath
//
//  Clarity's own first-run intro (Developer Mode only): four pages of
//  ink-on-paper line drawings — a circle, a rising line, a filling rule,
//  a closing ring. Completely separate from the real app's onboarding.
//

import SwiftUI

// MARK: - Page model

private enum ClarityArt {
    case mark, line, rule, ring
}

private struct ClarityPage: Identifiable {
    let id = UUID()
    let art: ClarityArt
    let overline: String
    let title: String
    let message: String
}

// MARK: - Container

struct ClarityOnboardingView: View {
    var onFinish: () -> Void

    @State private var page = 0
    @State private var started = false

    private let pages: [ClarityPage] = [
        ClarityPage(art: .mark, overline: "Welcome to Clarity",
                    title: "Your money,\nplainly told",
                    message: "Every number you need, none you don't. The same PennyPath, stripped back to what matters."),
        ClarityPage(art: .line, overline: "Know",
                    title: "One honest\nnumber",
                    message: "Everything you own minus everything you owe — and the story of how it's been changing."),
        ClarityPage(art: .rule, overline: "Plan",
                    title: "Spend with\nintent",
                    message: "A monthly plan sits beside every category, so you always know what's left before you spend it."),
        ClarityPage(art: .ring, overline: "Grow",
                    title: "Quiet\nprogress",
                    message: "Goals that pace themselves, and a health check made on your device. Nothing ever leaves your phone.")
    ]

    private var lastIndex: Int { pages.count - 1 }

    var body: some View {
        ZStack {
            Clarity.paper.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar

                TabView(selection: $page) {
                    ForEach(Array(pages.enumerated()), id: \.element.id) { index, item in
                        ClarityPageView(page: item, isActive: started && page == index)
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
                .font(.subheadline.weight(.medium))
                .foregroundStyle(Clarity.inkSoft)
                .opacity(page == lastIndex ? 0 : 1)
                .disabled(page == lastIndex)
        }
        .padding(.horizontal, 28)
        .padding(.top, 10)
        .frame(height: 40)
    }

    private var controls: some View {
        VStack(spacing: 22) {
            dots
            ClarityButton(title: page == lastIndex ? "Begin" : "Continue") {
                advance()
            }
        }
        .padding(.bottom, 36)
        .padding(.top, 10)
    }

    private var dots: some View {
        HStack(spacing: 7) {
            ForEach(0..<pages.count, id: \.self) { i in
                Capsule()
                    .fill(i == page ? Clarity.ink : Clarity.hairline)
                    .frame(width: i == page ? 22 : 7, height: 7)
            }
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.7), value: page)
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

// MARK: - A single page

private struct ClarityPageView: View {
    let page: ClarityPage
    let isActive: Bool

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 12)
            ClarityArtView(kind: page.art, isActive: isActive)
            Spacer(minLength: 30)
            VStack(spacing: 14) {
                ClarityOverline(text: page.overline, tint: Clarity.cobalt)
                Text(page.title)
                    .font(.clarityDisplay(34))
                    .foregroundStyle(Clarity.ink)
                    .multilineTextAlignment(.center)
                    .lineSpacing(2)
                Text(page.message)
                    .font(.callout)
                    .foregroundStyle(Clarity.inkSoft)
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .opacity(isActive ? 1 : 0)
            .offset(y: isActive ? 0 : 14)
            .animation(.easeOut(duration: 0.45).delay(0.05), value: isActive)
            Spacer(minLength: 16)
        }
        .padding(.horizontal, 36)
    }
}

// MARK: - Line drawings

private struct ClarityArtView: View {
    let kind: ClarityArt
    let isActive: Bool

    var body: some View {
        ZStack {
            switch kind {
            case .mark: mark
            case .line: line
            case .rule: rule
            case .ring: ring
            }
        }
        .frame(width: 240, height: 230)
        .opacity(isActive ? 1 : 0)
        .animation(.easeOut(duration: 0.5), value: isActive)
    }

    /// A single drawn circle with one cobalt point: one clear picture.
    private var mark: some View {
        ZStack {
            Circle()
                .trim(from: 0, to: isActive ? 1 : 0)
                .stroke(Clarity.ink, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 150, height: 150)
                .animation(.easeInOut(duration: 1.0).delay(0.2), value: isActive)
            Circle()
                .fill(Clarity.cobalt)
                .frame(width: 12)
                .scaleEffect(isActive ? 1 : 0.01)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.1),
                           value: isActive)
        }
    }

    /// A rising line drawn left to right, ending in a point and a number.
    private var line: some View {
        ZStack(alignment: .topLeading) {
            Path { p in
                p.move(to: .init(x: 10, y: 170))
                p.addCurve(to: .init(x: 220, y: 50),
                           control1: .init(x: 90, y: 165),
                           control2: .init(x: 150, y: 110))
            }
            .trim(from: 0, to: isActive ? 1 : 0)
            .stroke(Clarity.ink, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .animation(.easeInOut(duration: 1.0).delay(0.2), value: isActive)

            Circle()
                .fill(Clarity.cobalt)
                .frame(width: 10)
                .offset(x: 215, y: 45)
                .scaleEffect(isActive ? 1 : 0.01)
                .animation(.spring(response: 0.5, dampingFraction: 0.6).delay(1.1),
                           value: isActive)

            Text(money(12_450))
                .font(.clarityAmount(22))
                .foregroundStyle(Clarity.ink)
                .offset(x: 130, y: 8)
                .opacity(isActive ? 1 : 0)
                .animation(.easeOut(duration: 0.4).delay(1.2), value: isActive)
        }
        .frame(width: 240, height: 200)
    }

    /// A budget rule filling to a stop mark short of its limit.
    private var rule: some View {
        VStack(alignment: .leading, spacing: 26) {
            ForEach(0..<3, id: \.self) { i in
                let fills: [CGFloat] = [0.62, 0.38, 0.81]
                let emojis = ["🍔", "🚗", "🎮"]
                HStack(spacing: 14) {
                    Text(emojis[i]).font(.system(size: 20))
                    ZStack(alignment: .leading) {
                        Capsule().fill(Clarity.well).frame(height: 4)
                        Capsule()
                            .fill(i == 2 ? Clarity.amber : Clarity.ink)
                            .frame(width: isActive ? 160 * fills[i] : 3, height: 4)
                            .animation(.easeInOut(duration: 0.8).delay(0.3 + Double(i) * 0.2),
                                       value: isActive)
                    }
                    .frame(width: 160)
                }
            }
        }
    }

    /// A goal ring closing, with its pace written in the middle.
    private var ring: some View {
        ZStack {
            Circle()
                .stroke(Clarity.well, lineWidth: 3)
                .frame(width: 150, height: 150)
            Circle()
                .trim(from: 0, to: isActive ? 0.7 : 0.01)
                .stroke(Clarity.cobalt, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .frame(width: 150, height: 150)
                .animation(.easeInOut(duration: 1.1).delay(0.25), value: isActive)
            VStack(spacing: 3) {
                Text("70%")
                    .font(.clarityAmount(26))
                    .foregroundStyle(Clarity.ink)
                Text("on pace")
                    .font(.caption)
                    .foregroundStyle(Clarity.inkSoft)
            }
        }
    }
}
