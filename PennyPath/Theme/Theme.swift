//
//  Theme.swift
//  PennyPath
//
//  The single source of truth for the look of the app:
//  a clean black & white base, with one accent color per pillar —
//  GREEN for net worth, RED for spending, GOLD for goals.
//

import SwiftUI

enum Theme {

    // MARK: Surfaces (clean black & white base)

    /// The screen background. Light: soft gray. Dark: true black-ish.
    static let background = Color(.systemGroupedBackground)
    /// Cards and raised panels sit on top of the background.
    static let surface = Color(.secondarySystemGroupedBackground)
    /// A slightly raised fill used inside cards (chips, bars, wells).
    static let well = Color(.tertiarySystemGroupedBackground)

    // MARK: Text

    static let ink = Color(.label)             // primary text
    static let inkSecondary = Color(.secondaryLabel)
    static let inkTertiary = Color(.tertiaryLabel)
    static let hairline = Color(.separator)

    // MARK: Accents — one color per pillar

    /// Net worth. Money you keep and grow. (fresh emerald)
    static let green = Color.adaptive(light: 0x059669, dark: 0x34D399)
    /// Spending. Money that leaves. (warm coral-red)
    static let red = Color.adaptive(light: 0xF04438, dark: 0xFF7A6E)
    /// Goals. Dreams you are saving toward.
    static let gold = Color.adaptive(light: 0xB8860B, dark: 0xE9B84A)

    // MARK: Shape metrics

    enum Radius {
        static let card: CGFloat = 22
        static let panel: CGFloat = 16
        static let chip: CGFloat = 12
        static let pill: CGFloat = 999
    }

    enum Space {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 20
        static let xxl: CGFloat = 28
    }
}

// MARK: - Friendly, rounded typography (welcoming even for a 10 year old)

extension Font {
    static func display(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    /// Big money numbers. Rounded + monospaced digits so they line up neatly.
    static func amount(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: size, weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - Reusable card styling

private struct CardStyle: ViewModifier {
    var padding: CGFloat = Theme.Space.lg

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Theme.surface, in: RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
    }
}

extension View {
    /// Wrap content in the standard rounded card surface.
    func card(padding: CGFloat = Theme.Space.lg) -> some View {
        modifier(CardStyle(padding: padding))
    }
}
