//
//  SpectrumStyle.swift
//  PennyPath
//
//  Style kit for the Spectrum shell (Developer Mode only) — the Ember stacked
//  layout where every net-worth card wears its OWN sophisticated, muted colour
//  (pine, slate, bronze, plum, wine) instead of a grayscale ramp, with white
//  text on every card. The background is a single flat tone (no gradient) so the
//  refined deck is the star. Adaptive — a soft off-white in light, a deep neutral
//  charcoal in dark. Follows the app's Appearance setting. Only the look is
//  Spectrum's; every screen reads the real store and reuses the real forms and
//  services.
//

import SwiftUI

enum Spectrum {

    // MARK: Canvas — a single flat tone (no gradient), adaptive light/dark.

    static let canvas = Color.adaptive(light: 0xF4F4F5, dark: 0x131315)

    // MARK: Text on the canvas

    static let onCanvas = Color.adaptive(light: 0x111111, dark: 0xF5F5F5)
    static let onCanvasSoft = Color.adaptive(light: 0x555555, dark: 0xCFCFCF).opacity(0.95)

    // MARK: Furniture

    /// Signature accent — the deck's slate blue. Used for selected controls,
    /// the active tab, meters and tip highlights across the non-deck screens.
    static let accent = Color.adaptive(light: 0x2E4E7A, dark: 0x8AAAE0)
    static let accentSoft = Color.adaptive(light: 0x2E4E7A, dark: 0x8AAAE0)
    static let tabInactive = Color.adaptive(light: 0x9A9A9A, dark: 0x8C8C8C)
    /// Money leaving / over-budget — the deck's wine (deep in light, light in dark).
    static let spend = Color.adaptive(light: 0xA32D3E, dark: 0xE58B97)
    /// Under-budget / positive — the deck's teal.
    static let good = Color.adaptive(light: 0x1E6B5B, dark: 0x69C4AE)
    static let plus = Color.adaptive(light: 0x111111, dark: 0xF0F0F0)
    static let plusInk = Color.adaptive(light: 0xFFFFFF, dark: 0x111111)

    /// The full card palette, for colour-cycling data on the non-deck screens
    /// (spending categories, goals) so they share the deck's colours. Lighter
    /// variants in dark mode so thin bars and meters read on the dark panels.
    static let palette: [Color] = [
        .adaptive(light: 0x27685E, dark: 0x59D1BF),   // pine
        .adaptive(light: 0x2E4E7A, dark: 0x598CD1),   // slate
        .adaptive(light: 0x8C5622, dark: 0xD1873F),   // bronze
        .adaptive(light: 0x614674, dark: 0xB285D1),   // plum
        .adaptive(light: 0x893643, dark: 0xD15D6F),   // wine
    ]

    // MARK: Budget burn stages

    /// The five-step "thermometer" a budget bar climbs as it fills toward its
    /// limit: calm pine when barely touched → slate → plum → bronze (getting
    /// close) → wine (at / over the limit). Solid deck tones (same in light and
    /// dark) so the white label drawn over the fill always reads.
    static let burnStages: [Color] = [
        Color(hex: 0x27685E),   // pine   — barely spent
        Color(hex: 0x2E4E7A),   // slate
        Color(hex: 0x614674),   // plum
        Color(hex: 0x8C5622),   // bronze — getting close
        Color(hex: 0x893643),   // wine   — at / over the limit
    ]

    /// Pick the stage colour for how much of a budget has been spent (0…1+).
    static func burnStage(_ ratio: Double) -> Color {
        switch ratio {
        case ..<0.25: return burnStages[0]
        case ..<0.50: return burnStages[1]
        case ..<0.75: return burnStages[2]
        case ..<0.90: return burnStages[3]
        default:      return burnStages[4]
        }
    }

    /// Solid alert red for an OVER-budget bar — deep enough that the white label
    /// reads in both light and dark. Red is reserved for this, so an over-budget
    /// category bar reads unambiguously (no category uses red itself).
    static let overBudget = Color(hex: 0xA8323F)

    /// A fixed, sophisticated jewel tone per spending category — stable no matter
    /// how the bars are sorted, so each category always wears the same colour.
    /// Solid (same in light & dark) so the white bar label always reads. No reds —
    /// red is reserved for the "over budget" signal so it never reads ambiguously.
    static func categoryColor(_ category: ExpenseCategory) -> Color {
        switch category {
        case .food:          return Color(hex: 0x8C5622)   // bronze
        case .shopping:      return Color(hex: 0x614674)   // plum
        case .transport:     return Color(hex: 0x2E4E7A)   // slate blue
        case .rent:          return Color(hex: 0x357A52)   // forest green
        case .health:        return Color(hex: 0x21808A)   // teal
        case .subscriptions: return Color(hex: 0x4B3B8F)   // indigo
        case .fun:           return Color(hex: 0xA67D24)   // gold
        case .other:         return Color(hex: 0x5A6472)   // steel grey
        }
    }

    static let cardRadius: CGFloat = 28

    // MARK: Neutral surfaces (the boxes that sit on the flat canvas)

    /// The neutral panel/pill fill. On the flat dark canvas a black tint would
    /// vanish, so dark mode lifts with a faint white; light mode sits back with a
    /// faint black — either way a clean surface that reads on a gradient-free bg.
    static func glassFill(dark: Bool) -> Color {
        dark ? Color.white.opacity(0.09) : Color.black.opacity(0.05)
    }
    /// Hairline rim for those boxes: a faint light lip in the dark, a soft dark
    /// edge in the light.
    static func glassStroke(dark: Bool) -> Color {
        (dark ? Color.white : Color.black).opacity(dark ? 0.12 : 0.10)
    }
}

// MARK: - Money kinds (how real accounts group into Spectrum's deck)

/// The five net-worth groups Spectrum fans into a deck of cards. Each maps onto a
/// real `AccountCategory` so net-worth maths (assets add, debts subtract) stays
/// correct, and carries its own distinct jewel-tone gradient.
enum SpectrumMoneyKind: String, CaseIterable, Identifiable {
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
    static func of(_ category: AccountCategory) -> SpectrumMoneyKind {
        switch category {
        case .cash, .savings: return .cash
        case .investment: return .investment
        case .property: return .property
        case .otherAsset: return .receivable
        case .creditCard, .loan, .otherDebt: return .liability
        }
    }

    // MARK: Card palette — one sophisticated, muted tone per card, white text on all.

    /// Top colour of the card's gradient — a refined, desaturated tone unique to
    /// each money kind (pine, slate, bronze, plum, wine), so the deck reads as a
    /// curated palette rather than bright candy colours.
    var fill: Color {
        switch self {
        case .cash:       return Color(hex: 0x27685E)   // pine / teal
        case .investment: return Color(hex: 0x2E4E7A)   // slate blue
        case .property:   return Color(hex: 0x8C5622)   // bronze
        case .receivable: return Color(hex: 0x614674)   // plum
        case .liability:  return Color(hex: 0x893643)   // wine
        }
    }

    /// Bottom colour of the card's gradient — a deeper shade of the same tone.
    var fillBottom: Color {
        switch self {
        case .cash:       return Color(hex: 0x1C4F46)
        case .investment: return Color(hex: 0x233B5E)
        case .property:   return Color(hex: 0x6F4319)
        case .receivable: return Color(hex: 0x4B375C)
        case .liability:  return Color(hex: 0x6E2A34)
        }
    }

    /// Every jewel-tone card is deep enough to carry light text.
    var isLight: Bool { false }

    /// Primary text/number colour — near-white on every card.
    var primary: Color { Color(hex: 0xFBFBFC) }

    /// Secondary (subtitle) colour — a translucent white that reads on any hue.
    var secondary: Color { Color.white.opacity(0.78) }

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

// MARK: - Header (title + settings gear) shared by every Spectrum screen

struct SpectrumHeader: View {
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
                .foregroundStyle(Spectrum.onCanvas)
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
                .foregroundStyle(Spectrum.onCanvas)
                .frame(width: 42, height: 42)
                .background(Spectrum.glassFill(dark: scheme == .dark), in: Circle())
                .overlay(Circle().strokeBorder(Spectrum.glassStroke(dark: scheme == .dark), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Neutral content panel (Expenses / Goals / Insights cards)

private struct SpectrumPanelStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Spectrum.glassFill(dark: scheme == .dark),
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Spectrum.glassStroke(dark: scheme == .dark), lineWidth: 1)
            )
    }
}

extension View {
    /// A calm translucent card that reads on the grey canvas. Use for the
    /// non-deck screens (Expenses, Goals, Insights).
    func spectrumPanel(padding: CGFloat = 18, radius: CGFloat = 22) -> some View {
        modifier(SpectrumPanelStyle(padding: padding, radius: radius))
    }
}

// MARK: - Header pill (a labelled total)

struct SpectrumGlassPill: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let value: String
    /// Optional semantic tint — e.g. green for assets, red for liabilities.
    var tint: Color? = nil

    private var isDark: Bool { scheme == .dark }
    private var fill: Color {
        guard let tint else { return Spectrum.glassFill(dark: isDark) }
        return tint.opacity(isDark ? 0.20 : 0.13)
    }
    private var stroke: Color {
        guard let tint else { return Spectrum.glassStroke(dark: isDark) }
        return tint.opacity(isDark ? 0.40 : 0.28)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Spectrum.onCanvasSoft)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(tint ?? Spectrum.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(fill, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(stroke, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

// MARK: - Floating + button

struct SpectrumPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Spectrum.plusInk)
                .frame(width: 64, height: 64)
                .background(Spectrum.plus, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}
