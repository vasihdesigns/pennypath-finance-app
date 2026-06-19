//
//  VividStyle.swift
//  PennyPath
//
//  Style kit for the "Vivid" reskin (Developer Mode only): a bold, modern
//  fintech look — one confident violet brand color, oversized hero numbers
//  with the cents/symbol dialed back, a few color-blocked cards, soft card
//  elevation, and a warm greeting. Color is a hierarchy tool, never wallpaper,
//  so the app keeps its legibility. Only the look changes; every feature is
//  the real one.
//

import SwiftUI

enum Vivid {

    // MARK: Surfaces (subtle violet-tinted neutrals)

    static let bg = Color.adaptive(light: 0xF5F3FB, dark: 0x0C0B12)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x18161F)
    static let well = Color.adaptive(light: 0xEDEAF7, dark: 0x231F30)
    static let hairline = Color.adaptive(light: 0xE6E2F2, dark: 0x2C2839)

    // MARK: Ink

    static let ink = Color.adaptive(light: 0x161423, dark: 0xF3F1FA)
    static let inkSoft = Color.adaptive(light: 0x6C687E, dark: 0xA9A3BD)
    static let inkFaint = Color.adaptive(light: 0xA7A3B9, dark: 0x6A6580)

    // MARK: Brand — one confident voice

    /// The signature color: used for the active tab, the FAB, primary
    /// actions, and the net-worth hero. This is what makes it "Vivid".
    static let violet = Color.adaptive(light: 0x7A5BF7, dark: 0x9B82FF)
    /// The gradient partner — a deeper indigo for the hero sweep.
    static let indigo = Color.adaptive(light: 0x5A53E8, dark: 0x6E6BFF)

    // MARK: Money semantics (kept distinct from the brand)

    /// Growth, assets, good news.
    static let green = Color.adaptive(light: 0x16A34A, dark: 0x4ADE80)
    /// Spending, money leaving.
    static let coral = Color.adaptive(light: 0xF43F6E, dark: 0xFB7193)
    /// Goals and wins.
    static let gold = Color.adaptive(light: 0xE0930C, dark: 0xFBBF24)

    static let cardRadius: CGFloat = 28

    /// Colors for spending categories, biggest slice first.
    static let chartPalette: [Color] = [violet, coral, gold, green, indigo, inkSoft]

    /// The signature violet → indigo sweep used on the hero and the FAB.
    static var brandGradient: LinearGradient {
        LinearGradient(colors: [violet, indigo],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    // MARK: Split-amount parts

    /// Break a money value into a small lead (sign + currency symbol), a big
    /// integer, and an optional small fraction (".50"), so hero numbers can be
    /// rendered with the cents and symbol deliberately dialed back.
    static func amountParts(_ amount: Double) -> (lead: String, integer: String, fraction: String?) {
        let negative = amount < 0
        // Round to cents first so 12.999 → 13.00 (matches money()).
        let magnitude = (abs(amount) * 100).rounded() / 100
        let intPart = magnitude.rounded(.towardZero)
        let integer = intPart.formatted(.number.precision(.fractionLength(0)))
        let lead = (negative ? "−" : "") + AppSettings.currencySymbol
        var fraction: String?
        if magnitude.rounded() != magnitude {
            let cents = Int(((magnitude - intPart) * 100).rounded())
            fraction = String(format: ".%02d", cents)
        }
        return (lead, integer, fraction)
    }
}

// MARK: - Type (rounded, scaled with Dynamic Type)

extension Font {
    /// Big rounded display headings.
    static func vividDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .rounded)
    }
    /// Money numbers: rounded with lined-up digits.
    static func vividAmount(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - The hero number (big integer, quiet symbol + cents)

/// Renders money the way the mood board does: a large bold integer with the
/// currency symbol and cents smaller and dimmer, so the magnitude reads first.
struct VividAmount: View {
    let value: Double
    var size: CGFloat = 56
    var tint: Color = Vivid.ink
    /// On a colored hero the tint is white; dim the trim with opacity instead.
    var trimOpacity: Double = 0.55

    var body: some View {
        let parts = Vivid.amountParts(value)
        HStack(alignment: .firstTextBaseline, spacing: 1) {
            Text(parts.lead)
                .font(.vividDisplay(size * 0.46, weight: .semibold))
                .foregroundStyle(tint.opacity(trimOpacity))
            Text(parts.integer)
                .font(.vividAmount(size, weight: .heavy))
                .foregroundStyle(tint)
            if let fraction = parts.fraction {
                Text(fraction)
                    .font(.vividAmount(size * 0.46, weight: .semibold))
                    .foregroundStyle(tint.opacity(trimOpacity))
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .accessibilityElement()
        .accessibilityLabel(money(value))
    }
}

// MARK: - Small shared pieces

/// The uppercase, letterspaced section label ("NET WORTH", "GOALS"…).
struct VividOverline: View {
    let text: String
    var tint: Color = Vivid.inkSoft
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded).weight(.bold))
            .tracking(1.8)
            .foregroundStyle(tint)
    }
}

// MARK: - Card surface (soft elevation)

private struct VividCardStyle: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                Vivid.card,
                in: RoundedRectangle(cornerRadius: Vivid.cardRadius, style: .continuous)
            )
            .shadow(color: Vivid.violet.opacity(0.10), radius: 16, y: 8)
    }
}

extension View {
    /// Vivid's raised card surface.
    func vividCard(padding: CGFloat = 20) -> some View {
        modifier(VividCardStyle(padding: padding))
    }
}

// MARK: - Primary action (violet capsule)

struct VividPrimaryButton: View {
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
                Text(title).font(.system(.subheadline, design: .rounded).weight(.bold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 28)
            .background(Vivid.brandGradient, in: Capsule())
            .shadow(color: Vivid.violet.opacity(0.45), radius: 14, y: 6)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Segmented pill toggle (the time / mode control)

struct VividPills<T: Hashable>: View {
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
                        .font(.system(.footnote, design: .rounded).weight(.bold))
                        .foregroundStyle(on ? .white : Vivid.inkSoft)
                        .padding(.vertical, 7)
                        .padding(.horizontal, 14)
                        .background {
                            if on { Capsule().fill(Vivid.violet) }
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Vivid.well, in: Capsule())
    }
}

// MARK: - Donut (a ring with anything in its center)

struct VividDonut<Center: View>: View {
    var progress: Double          // 0...1
    var lineWidth: CGFloat = 20
    var track: Color = Vivid.well
    var gradient: LinearGradient = Vivid.brandGradient
    @ViewBuilder var center: () -> Center

    var body: some View {
        ZStack {
            Circle().stroke(track, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, progress)))
                .stroke(gradient, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.6), value: progress)
            center()
        }
    }
}

// MARK: - Avatar monogram (the warm, human opener)

/// A gradient avatar bubble. Tapping it is the screen's way into Settings.
struct VividMonogram: View {
    var size: CGFloat = 46
    var action: () -> Void

    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.42, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: size, height: size)
                .background(Vivid.brandGradient, in: Circle())
                .shadow(color: Vivid.violet.opacity(0.4), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Settings")
    }
}
