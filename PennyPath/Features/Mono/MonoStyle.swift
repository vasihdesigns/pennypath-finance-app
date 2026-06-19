//
//  MonoStyle.swift
//  PennyPath
//
//  Style kit for the Mono shell (Developer Mode only) — a strict black & white
//  version of the Ember layout. A fanned stack of cards in a pure grayscale
//  palette. Adaptive — dark mode is a near-black→silver canvas; light mode is a
//  white→light-grey canvas. The deck cards stay a constant charcoal→black ramp
//  with near-white text in both modes. Follows the app's Appearance setting.
//  Only the look is Mono's; every screen reads the real store and reuses the
//  real forms and services.
//

import SwiftUI

enum Mono {

    // MARK: Canvas (adaptive) — white→grey in light, near-black→silver in dark

    static let canvas = LinearGradient(
        colors: [Color.adaptive(light: 0xFFFFFF, dark: 0x0E0E0E),
                 Color.adaptive(light: 0xF4F4F4, dark: 0x242424),
                 Color.adaptive(light: 0xE4E4E4, dark: 0x595959),
                 Color.adaptive(light: 0xD2D2D2, dark: 0xBFBFBF)],
        startPoint: .top, endPoint: .bottom)

    // MARK: Text on the canvas

    static let onCanvas = Color.adaptive(light: 0x111111, dark: 0xF5F5F5)
    static let onCanvasSoft = Color.adaptive(light: 0x555555, dark: 0xCFCFCF).opacity(0.95)

    // MARK: Furniture

    static let accent = Color.adaptive(light: 0x1A1A1A, dark: 0xF0F0F0)   // near-black / near-white
    /// A mid-grey used in place of the accent on the Expenses & Goals screens
    /// (data bars, meters, selected controls) — dark-grey in light mode, light-
    /// grey in dark mode, so the active control always reads against its label.
    static let accentSoft = Color.adaptive(light: 0x4A4A4A, dark: 0xC4C4C4)
    static let tabInactive = Color.adaptive(light: 0x9A9A9A, dark: 0x8C8C8C)
    /// Money leaving / over-budget — a strong near-black (light) / near-white
    /// (dark); direction is carried by the arrow glyph, not hue.
    static let spend = Color.adaptive(light: 0x111111, dark: 0xF5F5F5)
    /// Under-budget / positive — a calm mid-grey.
    static let good = Color.adaptive(light: 0x6A6A6A, dark: 0xAEAEAE)
    static let plus = Color.adaptive(light: 0x111111, dark: 0xF0F0F0)
    static let plusInk = Color.adaptive(light: 0xFFFFFF, dark: 0x111111)

    static let cardRadius: CGFloat = 28

    // MARK: Smoked-glass surfaces (the neutral boxes that sit on the canvas)

    /// Dark, translucent fill — reads as smoked glass over the grey canvas in
    /// both modes, rather than a white-tinted lift.
    static func glassFill(dark: Bool) -> Color { Color.black.opacity(dark ? 0.32 : 0.10) }
    /// Hairline rim for those boxes: a faint light lip in the dark, a soft dark
    /// edge in the light.
    static func glassStroke(dark: Bool) -> Color {
        (dark ? Color.white : Color.black).opacity(dark ? 0.12 : 0.10)
    }
}

// MARK: - Money kinds (how real accounts group into Mono's deck)

/// The five net-worth groups Mono fans into a deck of cards. Each maps onto a
/// real `AccountCategory` so net-worth maths (assets add, debts subtract) stays
/// correct, and carries the grayscale gradient that paints its card.
enum MonoMoneyKind: String, CaseIterable, Identifiable {
    case cash, investment, property, receivable, liability
    var id: String { rawValue }

    var title: String {
        switch self {
        case .cash: return "Cash Equivalents"
        case .investment: return "Investment"
        case .property: return "Property"
        case .receivable: return "Receivable"
        case .liability: return "Liability"
        }
    }

    var symbol: String {
        switch self {
        case .cash: return "banknote.fill"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .property: return "house.fill"
        case .receivable: return "person.2.fill"
        case .liability: return "creditcard.fill"
        }
    }

    var isAsset: Bool { self != .liability }

    /// Where new entries of this kind are stored, so net-worth math stays right.
    var underlying: AccountCategory {
        switch self {
        case .cash: return .cash
        case .investment: return .investment
        case .property: return .property
        case .receivable: return .otherAsset
        case .liability: return .otherDebt
        }
    }

    /// Group an existing stored account into one of the five.
    static func of(_ category: AccountCategory) -> MonoMoneyKind {
        switch category {
        case .cash, .savings: return .cash
        case .investment: return .investment
        case .property: return .property
        case .otherAsset: return .receivable
        case .creditCard, .loan, .otherDebt: return .liability
        }
    }

    // MARK: Card palette — a light→dark grayscale staircase, constant in both modes.

    /// Top colour of the card's gradient. A wide ramp from pale silver (Cash)
    /// stepping down to pure black (Liability), so the stacked deck reads as a
    /// clear light-to-dark staircase — each card a visibly different shade.
    var fill: Color {
        switch self {
        case .cash:       return Color(hex: 0xDCDCDC)
        case .investment: return Color(hex: 0xACACAC)
        case .property:   return Color(hex: 0x6C6C6C)
        case .receivable: return Color(hex: 0x3A3A3A)
        case .liability:  return Color(hex: 0x121212)
        }
    }

    /// Bottom colour of the card's gradient.
    var fillBottom: Color {
        switch self {
        case .cash:       return Color(hex: 0xCBCBCB)
        case .investment: return Color(hex: 0x9C9C9C)
        case .property:   return Color(hex: 0x5E5E5E)
        case .receivable: return Color(hex: 0x2E2E2E)
        case .liability:  return Color(hex: 0x000000)
        }
    }

    /// The pale top-of-deck cards (Cash, Investment) carry dark text; the darker
    /// cards carry light text — so every label reads against its own shade.
    var isLight: Bool { self == .cash || self == .investment }

    /// Primary text/number colour — near-black on pale cards, near-white on dark.
    var primary: Color { isLight ? Color(hex: 0x161616) : Color(hex: 0xF5F5F5) }

    /// Secondary (subtitle) colour — a muted tone that reads on this card's shade.
    var secondary: Color { isLight ? Color(hex: 0x505050) : Color(hex: 0xCFCFCF) }

    /// Glossy top-left highlight for the card surface — a soft white gloss on the
    /// dark cards; barely-there on the pale ones (they need no lift).
    var sheen: [Color] {
        isLight ? [.white.opacity(0.35), .white.opacity(0.06), .clear]
                : [.white.opacity(0.20), .white.opacity(0.04), .clear]
    }

    /// Hairline rim that separates lapping cards — a light rim on the dark cards,
    /// a soft dark rim on the pale cards (where a white rim would vanish).
    var rim: [Color] {
        isLight ? [.black.opacity(0.16), .black.opacity(0.06), .black.opacity(0.02)]
                : [.white.opacity(0.55), .white.opacity(0.14), .white.opacity(0.04)]
    }
}

// MARK: - Header (title + settings gear) shared by every Mono screen

struct MonoHeader: View {
    @Environment(\.colorScheme) private var scheme
    let title: String
    /// Optional extra round button shown just left of the settings gear.
    var accessorySymbol: String? = nil
    var accessoryLabel: String = ""
    var onAccessory: (() -> Void)? = nil
    var onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.system(size: 26, weight: .semibold))
                .foregroundStyle(Mono.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            if let accessorySymbol, let onAccessory {
                iconButton(accessorySymbol, label: accessoryLabel, action: onAccessory)
            }
            iconButton("gearshape.fill", label: "Settings", action: onSettings)
        }
    }

    private func iconButton(_ symbol: String, label: String,
                            action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Mono.onCanvas)
                .frame(width: 42, height: 42)
                .background(Mono.glassFill(dark: scheme == .dark), in: Circle())
                .overlay(Circle().strokeBorder(Mono.glassStroke(dark: scheme == .dark), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Neutral content panel (Expenses / Goals / Insights cards)

private struct MonoPanelStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Mono.glassFill(dark: scheme == .dark),
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Mono.glassStroke(dark: scheme == .dark), lineWidth: 1)
            )
    }
}

extension View {
    /// A calm translucent card that reads on the grey canvas. Use for the
    /// non-deck screens (Expenses, Goals, Insights).
    func monoPanel(padding: CGFloat = 18, radius: CGFloat = 22) -> some View {
        modifier(MonoPanelStyle(padding: padding, radius: radius))
    }
}

// MARK: - Header pill (a labelled total)

struct MonoGlassPill: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Mono.onCanvasSoft)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Mono.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Mono.glassFill(dark: scheme == .dark),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Mono.glassStroke(dark: scheme == .dark), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

// MARK: - Floating + button

struct MonoPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Mono.plusInk)
                .frame(width: 64, height: 64)
                .background(Mono.plus, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}
