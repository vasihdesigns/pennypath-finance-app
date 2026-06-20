//
//  PaywallView.swift
//  PennyPath
//
//  A single-screen "PennyPath Plus" paywall, dressed in the Spectrum jewel-tone
//  vocabulary — soft blurred backdrop blobs, a floating membership card cut from
//  the deck's pine→slate→bronze→plum→wine palette, a tight feature list, a
//  two-up plan picker, and one clear call to action. Presentational: the purchase
//  button is wired to a placeholder ready for StoreKit 2. Reached from Settings.
//

import SwiftUI

// MARK: - Plans

private enum PaywallPlan: String, CaseIterable, Identifiable {
    case yearly, monthly
    var id: String { rawValue }

    var title: String { self == .yearly ? "Yearly" : "Monthly" }

    /// Headline price for the card.
    var price: String { self == .yearly ? "39.99" : "4.99" }
    var per: String { self == .yearly ? "/year" : "/month" }

    /// The small line under the price.
    var caption: String {
        self == .yearly ? "Just \(AppSettings.currencySymbol)3.33 / month" : "Billed monthly"
    }

    /// Ribbon shown only on the best-value plan.
    var ribbon: String? { self == .yearly ? "SAVE 33%" : nil }

    /// CTA fine print for this plan.
    var finePrint: String {
        "7 days free, then \(AppSettings.currencySymbol)\(price)\(per). Cancel anytime."
    }
}

// MARK: - Screen

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var scheme

    @State private var plan: PaywallPlan = .yearly
    @State private var appear = false
    @State private var float = false

    /// The five deck tones, used for the card gradient and feature icons.
    private let jewels: [Color] = SpectrumMoneyKind.allCases.map(\.fill)

    private let features: [(String, String, String)] = [
        ("infinity", "Unlimited accounts & holdings", "Track every wallet, card, and investment — no caps."),
        ("chart.bar.fill", "Budgets for every category", "See each budget fill and shift colour as you spend."),
        ("chart.line.uptrend.xyaxis", "Live prices & exchange rates", "Markets and FX refresh so your net worth stays true."),
        ("icloud.fill", "iCloud sync across devices", "Your private world, on every iPhone and iPad you own."),
        ("sparkles", "Smart insights & coaching", "Quiet, on-device tips drawn from your own numbers."),
    ]

    var body: some View {
        ZStack {
            Spectrum.canvas.ignoresSafeArea()
            backdrop
            ScrollView {
                VStack(spacing: 15) {
                    hero
                    headline
                    featureList
                    planPicker
                    callToAction
                    footer
                }
                .padding(.horizontal, 24)
                .padding(.top, 2)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
            closeButton
        }
        .onAppear {
            appear = true
            float = true
        }
    }

    // MARK: Backdrop — two soft jewel blobs, like the onboarding canvas

    private var backdrop: some View {
        ZStack {
            Circle().fill(jewels[1].opacity(scheme == .dark ? 0.34 : 0.18))
                .frame(width: 380, height: 380).blur(radius: 100)
                .offset(x: -130, y: -240)
            Circle().fill(jewels[3].opacity(scheme == .dark ? 0.26 : 0.14))
                .frame(width: 340, height: 340).blur(radius: 100)
                .offset(x: 150, y: 220)
        }
        .allowsHitTesting(false)
    }

    private var closeButton: some View {
        VStack {
            HStack {
                Spacer()
                Button {
                    Haptics.tap()
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                        .frame(width: 34, height: 34)
                        .background(Spectrum.glassFill(dark: scheme == .dark), in: Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Close")
            }
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }

    // MARK: Hero — a floating "Plus" membership card cut from the deck palette

    private var hero: some View {
        ZStack {
            // Soft glow puddle beneath the card.
            Ellipse()
                .fill(jewels[3].opacity(0.45))
                .frame(width: 230, height: 40)
                .blur(radius: 26)
                .offset(y: 78)

            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(LinearGradient(colors: jewels,
                                     startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 290, height: 138)
                .overlay(sheen)
                .overlay(cardFace)
                .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(.white.opacity(0.22), lineWidth: 1))
                .shadow(color: .black.opacity(0.30), radius: 22, y: 14)
                .rotation3DEffect(.degrees(appear ? 0 : 18),
                                  axis: (x: 1, y: -0.4, z: 0), perspective: 0.7)
                .offset(y: float ? -6 : 6)
                .animation(.easeInOut(duration: 2.8).repeatForever(autoreverses: true), value: float)
        }
        .frame(height: 168)
        .scaleEffect(appear ? 1 : 0.86)
        .opacity(appear ? 1 : 0)
        .animation(.spring(response: 0.7, dampingFraction: 0.78), value: appear)
    }

    private var sheen: some View {
        RoundedRectangle(cornerRadius: 24, style: .continuous)
            .fill(LinearGradient(colors: [.white.opacity(0.28), .white.opacity(0.04), .clear],
                                 startPoint: .topLeading, endPoint: .center))
    }

    private var cardFace: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PENNYPATH")
                    .font(.system(size: 12, weight: .heavy)).tracking(2)
                    .foregroundStyle(.white.opacity(0.85))
                Spacer()
                Image(systemName: "sparkles")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(.white)
            }
            Spacer()
            Text("Plus")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.white)
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .bold))
                Text("MEMBER")
                    .font(.system(size: 11, weight: .bold)).tracking(1.5)
            }
            .foregroundStyle(.white.opacity(0.9))
        }
        .padding(18)
    }

    private var headline: some View {
        VStack(spacing: 8) {
            Text("Unlock everything")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Spectrum.onCanvas)
            Text("One membership for your whole financial world.")
                .font(.system(size: 15))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 10)
        .animation(.easeOut(duration: 0.45).delay(0.1), value: appear)
    }

    // MARK: Features

    private var featureList: some View {
        VStack(spacing: 11) {
            ForEach(Array(features.enumerated()), id: \.offset) { i, f in
                featureRow(symbol: f.0, title: f.1, detail: f.2,
                           tint: jewels[i % jewels.count], index: i)
            }
        }
    }

    private func featureRow(symbol: String, title: String, detail: String,
                            tint: Color, index: Int) -> some View {
        HStack(alignment: .center, spacing: 14) {
            ZStack {
                Circle().fill(tint.opacity(scheme == .dark ? 0.30 : 0.16))
                Image(systemName: symbol)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(tint)
            }
            .frame(width: 42, height: 42)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15.5, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvas)
                Text(detail)
                    .font(.system(size: 13))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .opacity(appear ? 1 : 0)
        .offset(x: appear ? 0 : -16)
        .animation(.easeOut(duration: 0.4).delay(0.18 + Double(index) * 0.06), value: appear)
    }

    // MARK: Plan picker — two cards side by side

    private var planPicker: some View {
        HStack(spacing: 12) {
            ForEach(PaywallPlan.allCases) { p in
                planCard(p)
            }
        }
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.45).delay(0.42), value: appear)
    }

    private func planCard(_ p: PaywallPlan) -> some View {
        let selected = plan == p
        return Button {
            Haptics.tap()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) { plan = p }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Text(p.title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Spectrum.onCanvasSoft)
                HStack(alignment: .firstTextBaseline, spacing: 1) {
                    Text(AppSettings.currencySymbol)
                        .font(.system(size: 16, weight: .bold))
                    Text(p.price)
                        .font(.system(size: 26, weight: .bold))
                    Text(p.per)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Spectrum.onCanvasSoft)
                }
                .foregroundStyle(Spectrum.onCanvas)
                Text(p.caption)
                    .font(.system(size: 12))
                    .foregroundStyle(Spectrum.onCanvasSoft)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(planFill(selected: selected),
                        in: RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(selected ? Spectrum.accent : Spectrum.glassStroke(dark: scheme == .dark),
                                  lineWidth: selected ? 2 : 1)
            )
            .overlay(alignment: .topTrailing) { ribbon(p) }
            .overlay(alignment: .bottomTrailing) {
                if selected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(Spectrum.accent)
                        .padding(10)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func planFill(selected: Bool) -> Color {
        let base = Spectrum.glassFill(dark: scheme == .dark)
        return selected ? Spectrum.accent.opacity(scheme == .dark ? 0.18 : 0.10) : base
    }

    @ViewBuilder
    private func ribbon(_ p: PaywallPlan) -> some View {
        if let text = p.ribbon {
            Text(text)
                .font(.system(size: 10, weight: .heavy)).tracking(0.5)
                .foregroundStyle(.white)
                .padding(.horizontal, 9).padding(.vertical, 4)
                .background(Spectrum.good, in: Capsule())
                .offset(x: -10, y: -10)
        }
    }

    // MARK: Call to action

    private var callToAction: some View {
        VStack(spacing: 10) {
            Button {
                Haptics.success()
                // Presentational paywall — wire StoreKit 2 purchase here.
                dismiss()
            } label: {
                Text("Start 7-day free trial")
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Spectrum.plusInk)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 17)
                    .background(Spectrum.plus, in: Capsule())
            }
            .buttonStyle(.plain)
            Text(plan.finePrint)
                .font(.system(size: 12))
                .foregroundStyle(Spectrum.onCanvasSoft)
                .multilineTextAlignment(.center)
        }
        .opacity(appear ? 1 : 0)
        .offset(y: appear ? 0 : 12)
        .animation(.spring(response: 0.5, dampingFraction: 0.85).delay(0.5), value: appear)
    }

    // MARK: Footer

    private var footer: some View {
        HStack(spacing: 10) {
            Button("Restore") {
                Haptics.tap()
                // Wire StoreKit restore here.
            }
            divider
            Link("Terms", destination: SupportLinks.terms)
            divider
            Link("Privacy", destination: SupportLinks.privacyPolicy)
        }
        .font(.system(size: 12, weight: .medium))
        .foregroundStyle(Spectrum.onCanvasSoft)
        .tint(Spectrum.onCanvasSoft)
        .opacity(appear ? 1 : 0)
        .animation(.easeOut(duration: 0.4).delay(0.58), value: appear)
    }

    private var divider: some View {
        Text("·").foregroundStyle(Spectrum.onCanvasSoft.opacity(0.6))
    }
}

#Preview {
    PaywallView()
}
