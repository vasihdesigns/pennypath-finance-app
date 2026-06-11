//
//  VerdeStyle.swift
//  PennyPath
//
//  A self-contained "Verde" design language used only by the two Developer-Mode
//  Home experiments (HomeViewVerde, HomeViewVerdeLite). It deliberately does NOT
//  touch the real app's Theme — its own porcelain/pine palette, leaf + apricot +
//  mist accents, eyebrow labels, and light-weight display type live here.
//

import SwiftUI

enum Verde {
    // Surfaces & ink (porcelain + deep pine; inverts to forest + porcelain in dark)
    static let bg = Color.adaptive(light: 0xF2F4F1, dark: 0x131D19)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x1C2A24)
    static let ink = Color.adaptive(light: 0x1C2B26, dark: 0xECF1EC)
    static var faint: Color { ink.opacity(0.55) }
    static var ghost: Color { ink.opacity(0.34) }
    static var line: Color { ink.opacity(0.10) }

    // Accents
    static let leaf = Color.adaptive(light: 0x2E7D5B, dark: 0x63C295)     // growth
    static let apricot = Color.adaptive(light: 0xD96F3F, dark: 0xE79268)  // spending
    static let mist = Color.adaptive(light: 0x8FA8C7, dark: 0xA6BEDC)     // neutral data
    static var leafSoft: Color { leaf.opacity(0.12) }

    /// Light-weight display type (stand-in for Bricolage Grotesque).
    static func display(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}

/// Tiny uppercase, wide-tracked label — the signature "eyebrow".
struct VerdeEyebrow: View {
    let text: String
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(2)
            .foregroundStyle(Verde.ghost)
    }
}

/// Soft white card with a hairline edge and a gentle shadow.
struct VerdeCard<Content: View>: View {
    var padding: CGFloat = 20
    var fill: Color = Verde.card
    var border: Color = Verde.line
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(fill, in: RoundedRectangle(cornerRadius: 24, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .strokeBorder(border, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 2)
    }
}

/// A small pill showing a signed change, leaf for up / apricot for down.
struct VerdeChangePill: View {
    let amount: Double
    var suffix: String = "this month"

    var body: some View {
        let up = amount >= 0
        let color = up ? Verde.leaf : Verde.apricot
        return HStack(spacing: 6) {
            Image(systemName: up ? "arrow.up.right" : "arrow.down.right")
                .font(.system(size: 9, weight: .bold))
            Text("\(up ? "+" : "−")\(money(abs(amount))) \(suffix)")
                .font(.system(size: 12.5, weight: .semibold))
        }
        .foregroundStyle(color)
        .padding(.vertical, 5)
        .padding(.horizontal, 12)
        .background(color.opacity(0.12), in: Capsule())
    }
}
