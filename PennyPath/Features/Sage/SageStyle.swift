//
//  SageStyle.swift
//  PennyPath
//
//  Style kit for the "Sage" reskin (Developer Mode only): a calm,
//  editorial look — warm sage-tinted background, soft white cards,
//  uppercase tracked overlines, and a quiet green/terracotta/slate
//  palette. Only the look changes; every feature is the real one.
//

import SwiftUI

enum Sage {

    // MARK: Surfaces

    /// Warm off-white with a hint of sage. Dark: deep green-charcoal.
    static let bg = Color.adaptive(light: 0xF2F3EE, dark: 0x121613)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x1C231E)
    static let well = Color.adaptive(light: 0xE9EBE3, dark: 0x262E28)
    static let hairline = Color.adaptive(light: 0xE3E5DC, dark: 0x2C342E)

    // MARK: Ink

    static let ink = Color.adaptive(light: 0x232C26, dark: 0xE9EDE8)
    static let inkSoft = Color.adaptive(light: 0x8C948C, dark: 0x97A099)
    static let inkFaint = Color.adaptive(light: 0xB3B9B0, dark: 0x6B746D)

    // MARK: Accents

    /// The one brand color: a muted botanical green.
    static let green = Color.adaptive(light: 0x4D7A5B, dark: 0x86B494)
    /// Deep green-charcoal, used for the biggest spending segment.
    static let charcoal = Color.adaptive(light: 0x27312A, dark: 0xCDD6CF)
    /// Liabilities and overspend.
    static let terracotta = Color.adaptive(light: 0xC2632F, dark: 0xDB8B55)
    /// The cool counterpoint.
    static let slate = Color.adaptive(light: 0x96A8C8, dark: 0x8FA5C8)

    static let cardRadius: CGFloat = 26

    /// Colors for spending categories, biggest slice first.
    static let chartPalette: [Color] = [charcoal, green, terracotta, slate, inkSoft, inkFaint]
}

// MARK: - Type

extension Font {
    /// Big editorial headings (scaled with Dynamic Type).
    static func sageDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: Font.scaled(size), weight: weight)
    }
    /// Big money numbers with lined-up digits (scaled with Dynamic Type).
    static func sageAmount(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: Font.scaled(size), weight: weight).monospacedDigit()
    }
}

// MARK: - Small shared pieces

/// The uppercase, letterspaced section label ("NET WORTH", "GOALS"…).
struct SageOverline: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.caption.weight(.semibold))
            .tracking(2.2)
            .foregroundStyle(Sage.inkSoft)
    }
}

private struct SageCardStyle: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                Sage.card,
                in: RoundedRectangle(cornerRadius: Sage.cardRadius, style: .continuous)
            )
            .shadow(color: .black.opacity(0.04), radius: 14, y: 6)
    }
}

extension View {
    func sageCard(padding: CGFloat = 20) -> some View {
        modifier(SageCardStyle(padding: padding))
    }
}
