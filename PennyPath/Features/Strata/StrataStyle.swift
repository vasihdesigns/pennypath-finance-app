//
//  StrataStyle.swift
//  PennyPath
//
//  Style kit for the "Strata" reskin (Developer Mode only): an asset-first
//  net-worth tracker in the spirit of Percento — a bold periwinkle canvas,
//  crisp white cards, a big plain net-worth number with a privacy eye, and
//  the signature move: net worth shown as proportional color bands (strata)
//  sized by each category's share, with debts protruding. Professional
//  system sans, not rounded. Only the look changes; every feature is real.
//

import SwiftUI

enum Strata {

    // MARK: Canvas — the signature periwinkle

    /// The brand background. Periwinkle in light, deep indigo at night.
    static let bg = Color.adaptive(light: 0x6366D6, dark: 0x15162A)
    /// A pale periwinkle for soft buttons / wells on the canvas.
    static let brandSoft = Color.adaptive(light: 0xE6E7FB, dark: 0x2A2C52)

    // MARK: Cards

    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x20223B)
    static let well = Color.adaptive(light: 0xF0F0F7, dark: 0x2C2E4C)
    static let hairline = Color.adaptive(light: 0xEAEAF2, dark: 0x33355A)

    // MARK: Ink (inside white cards)

    static let ink = Color.adaptive(light: 0x161730, dark: 0xF2F2F8)
    static let inkSoft = Color.adaptive(light: 0x6B6E88, dark: 0x9C9EB8)
    static let inkFaint = Color.adaptive(light: 0xA7A9BE, dark: 0x66688C)

    // MARK: Ink on the periwinkle canvas

    static let onBrand = Color.adaptive(light: 0x171834, dark: 0xF3F3FA)
    static let onBrandSoft = Color.adaptive(light: 0x3C3E6E, dark: 0xB9BBDA)

    // MARK: The strata palette (one color per money kind)

    static let cash = Color.adaptive(light: 0x3FBE6B, dark: 0x53D183)
    static let savings = Color.adaptive(light: 0x14A088, dark: 0x39C3AA)
    static let investment = Color.adaptive(light: 0x5A4FCF, dark: 0x8E84F2)
    static let property = Color.adaptive(light: 0x4C84E8, dark: 0x6FA0F4)
    static let otherAsset = Color.adaptive(light: 0x97A2F1, dark: 0xAAB3F6)
    static let creditCard = Color.adaptive(light: 0x8B90A6, dark: 0xA7ABC0)
    static let loan = Color.adaptive(light: 0xAAAFC2, dark: 0x888CA6)
    static let otherDebt = Color.adaptive(light: 0xC3C7D6, dark: 0x6F7392)

    static let cardRadius: CGFloat = 18

    /// The band color for an account category.
    static func color(for category: AccountCategory) -> Color {
        switch category {
        case .cash: return cash
        case .savings: return savings
        case .investment: return investment
        case .property: return property
        case .otherAsset: return otherAsset
        case .creditCard: return creditCard
        case .loan: return loan
        case .otherDebt: return otherDebt
        }
    }

    /// Colors for spending categories, biggest slice first.
    static let chartPalette: [Color] = [investment, property, cash, savings, otherAsset, inkSoft]
}

// MARK: - Type (professional system sans)

extension Font {
    static func strataDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight)
    }
    static func strataAmount(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight).monospacedDigit()
    }
}

// MARK: - Card surface

private struct StrataCardStyle: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Strata.card,
                        in: RoundedRectangle(cornerRadius: Strata.cardRadius, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 12, y: 5)
    }
}

extension View {
    func strataCard(padding: CGFloat = 16) -> some View {
        modifier(StrataCardStyle(padding: padding))
    }
}

// MARK: - Small shared pieces

/// Section label. Defaults to the on-canvas color; pass a tint inside cards.
struct StrataOverline: View {
    let text: String
    var tint: Color = Strata.onBrandSoft
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .default).weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(tint)
    }
}

/// The round "+" button used on the canvas.
struct StrataPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Strata.bg)
                .frame(width: 40, height: 40)
                .background(.white, in: Circle())
                .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

/// Primary action inside a sheet/card (filled periwinkle capsule).
struct StrataPrimaryButton: View {
    let title: String
    var systemImage: String?
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 7) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 14, weight: .bold))
                }
                Text(title).font(.system(.subheadline).weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 28)
            .background(Strata.bg, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Segmented pill control (active = solid periwinkle), used for the
/// Trend / P&L toggles and the time-range selectors.
struct StrataPills<T: Hashable>: View {
    let items: [T]
    let title: (T) -> String
    @Binding var selection: T

    var body: some View {
        HStack(spacing: 3) {
            ForEach(items, id: \.self) { item in
                let on = item == selection
                Button {
                    Haptics.tap()
                    withAnimation(.snappy) { selection = item }
                } label: {
                    Text(title(item))
                        .font(.system(.footnote).weight(.semibold))
                        .foregroundStyle(on ? .white : Strata.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background {
                            if on { Capsule().fill(Strata.bg) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Strata.well, in: Capsule())
    }
}

// MARK: - The signature: proportional composition bar (strata)

/// One band of the composition.
struct StrataBand: Identifiable {
    let id = UUID()
    let color: Color
    let label: String
    let value: Double
    let share: Double        // value / total assets
    let isLiability: Bool
}

/// Net worth drawn as stacked proportional bands: assets fill the bar to
/// 100% of total assets; liabilities hang below, inset and gray, to show
/// they pull the total down. Big share labels appear where a band is tall
/// enough; everything is also listed in the cards below for VoiceOver.
struct StrataComposition: View {
    let bands: [StrataBand]
    /// Pixel height that represents 100% of total assets.
    var assetsHeight: CGFloat = 210

    var body: some View {
        VStack(spacing: 3) {
            ForEach(bands) { band in
                let h = max(6, band.share * assetsHeight)
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(band.color)
                    if h >= 34 {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(percentText(band.share))
                                .font(.strataAmount(h >= 58 ? 22 : 16, weight: .heavy))
                            Text(band.label)
                                .font(.system(.caption, design: .default).weight(.medium))
                                .lineLimit(1)
                        }
                        .foregroundStyle(.white)
                        .padding(.horizontal, 14)
                    }
                }
                .frame(height: h)
                // Liabilities are inset from the right so they "hang off".
                .padding(.trailing, band.isLiability ? 56 : 0)
                .padding(.leading, band.isLiability ? 0 : 0)
            }
        }
        .accessibilityHidden(true)   // the card list reads every value
    }
}
