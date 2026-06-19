//
//  ClarityStyle.swift
//  PennyPath
//
//  Style kit for the "Clarity" reskin (Developer Mode only): ink on
//  paper. Serif display type like a financial journal, hairline rules
//  instead of card chrome, generous whitespace, and a single cobalt
//  accent — green and rust appear only when money semantics demand it.
//  Only the look changes; every feature is the real one.
//

import SwiftUI

enum Clarity {

    // MARK: Paper

    static let paper = Color.adaptive(light: 0xFAF9F6, dark: 0x111113)
    static let well = Color.adaptive(light: 0xF1EFE9, dark: 0x1C1C1F)
    static let hairline = Color.adaptive(light: 0xE7E4DC, dark: 0x2A2A2E)

    // MARK: Ink

    static let ink = Color.adaptive(light: 0x1D1C1A, dark: 0xEDECE7)
    static let inkSoft = Color.adaptive(light: 0x7A776E, dark: 0x99988F)
    static let inkFaint = Color.adaptive(light: 0xB3B0A6, dark: 0x5B5A55)

    // MARK: Voice

    /// The one brand accent: a calm cobalt, used for actions and emphasis.
    static let cobalt = Color.adaptive(light: 0x3457C4, dark: 0x93A9F2)
    /// Money going right.
    static let good = Color.adaptive(light: 0x2E7D55, dark: 0x6FBF95)
    /// Money needing attention.
    static let rust = Color.adaptive(light: 0xB5503A, dark: 0xDE8870)
    /// Somewhere in between.
    static let amber = Color.adaptive(light: 0xA87A2A, dark: 0xD9AE5F)
}

// MARK: - Type (a financial journal: serif display, sans details)

extension Font {
    /// Serif headings — the "journal" voice (scaled with Dynamic Type).
    static func clarityDisplay(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .serif)
    }
    /// Serif money numbers with lined-up digits.
    static func clarityAmount(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .serif).monospacedDigit()
    }
}

// MARK: - Small shared pieces

/// The tiny uppercase section label ("NET WORTH", "THIS MONTH"…).
struct ClarityOverline: View {
    let text: String
    var tint: Color = Clarity.inkFaint
    var body: some View {
        Text(text.uppercased())
            .font(.caption2.weight(.semibold))
            .tracking(2.0)
            .foregroundStyle(tint)
    }
}

/// A full-width hairline rule.
struct ClarityRule: View {
    var body: some View {
        Clarity.hairline.frame(height: 1)
    }
}

/// Clarity's primary action: a quiet ink capsule.
struct ClarityButton: View {
    let title: String
    var tint: Color = Clarity.ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(Clarity.paper)
                .padding(.vertical, 13)
                .padding(.horizontal, 26)
                .background(tint, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A bordered, lighter-weight action.
struct ClarityGhostButton: View {
    let title: String
    var systemImage: String?
    var tint: Color = Clarity.ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage).font(.system(size: 12, weight: .semibold))
                }
                Text(title).font(.footnote.weight(.semibold))
            }
            .foregroundStyle(tint)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            .background {
                Capsule().strokeBorder(tint.opacity(0.35), lineWidth: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

/// The thin progress rule Clarity uses instead of chunky bars.
struct ClarityMeter: View {
    let value: Double          // 0...1
    var tint: Color = Clarity.ink

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Clarity.well)
                Capsule()
                    .fill(tint)
                    .frame(width: max(3, geo.size.width * min(1, max(0, value))))
            }
        }
        .frame(height: 4)
        .animation(.easeInOut(duration: 0.5), value: value)
    }
}
