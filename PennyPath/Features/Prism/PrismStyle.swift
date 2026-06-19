//
//  PrismStyle.swift
//  PennyPath
//
//  Style kit for the "Prism" reskin (Developer Mode only): a calm, flat
//  neutral canvas where every money kind is an OPAQUE, muted, diagonally
//  graded card — hue-coded by category (assets cool, debts warm). No glass,
//  no translucency: the gradient lives inside the boxes, the background stays
//  flat, and white text always sits on a deep-enough fill. Only the look
//  changes; every feature is the real one.
//

import SwiftUI

enum Prism {

    // MARK: Canvas — flat, neutral (the boxes are the colour, not this)

    static let bg = Color.adaptive(light: 0xF5F4F1, dark: 0x101114)

    // MARK: Neutral surfaces (lists, secondary cards)

    static let surface = Color.adaptive(light: 0xFFFFFF, dark: 0x1B1C20)
    static let well = Color.adaptive(light: 0xF0EFEB, dark: 0x26272C)
    static let hairline = Color.adaptive(light: 0xE7E6E1, dark: 0x303137)

    // MARK: Ink (on canvas / neutral cards)

    static let ink = Color.adaptive(light: 0x16181D, dark: 0xF1F1F4)
    static let inkSoft = Color.adaptive(light: 0x6B6E78, dark: 0x9A9DA8)
    static let inkFaint = Color.adaptive(light: 0xA6A8B0, dark: 0x636570)

    /// The accent the user kept — the app's green. Active tab + buttons.
    static let accent = Color.adaptive(light: 0x2E9E6B, dark: 0x43C489)

    static let cardRadius: CGFloat = 20

    // MARK: The muted, hue-coded gradient palette (one ramp per money kind)

    /// Start/end of each category's diagonal gradient. Tuned muted (low
    /// saturation) and deep enough that white text clears it in both modes —
    /// so the coloured cards read identically in light and dark; only the
    /// flat canvas flips.
    private static func ramp(for category: AccountCategory) -> (UInt, UInt) {
        switch category {
        // Assets — cool / green
        case .cash:       return (0x3AA873, 0x1F8255)   // green
        case .savings:    return (0x2D9A8C, 0x176B61)   // teal
        case .investment: return (0x6258B8, 0x3C3580)   // indigo
        case .property:   return (0x3E73B0, 0x274F7E)   // blue
        case .otherAsset: return (0x6A6FAE, 0x474B82)   // periwinkle
        // Debts — warm
        case .creditCard: return (0xB66445, 0x86412A)   // terracotta
        case .loan:       return (0xAA4E59, 0x7A333E)   // brick rose
        case .otherDebt:  return (0x8E5C7C, 0x644058)   // mauve
        }
    }

    static func gradient(for category: AccountCategory) -> LinearGradient {
        let (a, b) = ramp(for: category)
        return LinearGradient(colors: [Color(hex: a), Color(hex: b)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// A solid representative colour (the lighter ramp stop) for small chips,
    /// dots and meters where a flat fill reads better than a gradient.
    static func tint(for category: AccountCategory) -> Color {
        Color(hex: ramp(for: category).0)
    }

    // MARK: Spending palette (cycled by slice order)

    private static let chartRamps: [(UInt, UInt)] = [
        (0x6258B8, 0x3C3580),   // indigo
        (0x3E73B0, 0x274F7E),   // blue
        (0x2D9A8C, 0x176B61),   // teal
        (0x3AA873, 0x1F8255),   // green
        (0xC08A3A, 0x8A5F1E),   // amber
        (0xB66445, 0x86412A),   // terracotta
        (0x8E5C7C, 0x644058),   // mauve
        (0x6A6FAE, 0x474B82)    // periwinkle
    ]

    static func chartGradient(_ index: Int) -> LinearGradient {
        let (a, b) = chartRamps[index % chartRamps.count]
        return LinearGradient(colors: [Color(hex: a), Color(hex: b)],
                              startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    static func chartTint(_ index: Int) -> Color {
        Color(hex: chartRamps[index % chartRamps.count].0)
    }
}

// MARK: - Type (professional system sans)

extension Font {
    static func prismDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight)
    }
    static func prismAmount(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight).monospacedDigit()
    }
}

// MARK: - Card surfaces

/// A hue-coded gradient box — the signature surface. White content sits on it.
private struct PrismGradientCardStyle: ViewModifier {
    var gradient: LinearGradient
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(gradient,
                        in: RoundedRectangle(cornerRadius: Prism.cardRadius, style: .continuous))
            .overlay(
                // A hairline top-light so the box reads as a lit, solid panel.
                RoundedRectangle(cornerRadius: Prism.cardRadius, style: .continuous)
                    .strokeBorder(.white.opacity(0.12), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.14), radius: 14, y: 6)
    }
}

/// A flat neutral surface for lists and secondary content.
private struct PrismSurfaceCardStyle: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Prism.surface,
                        in: RoundedRectangle(cornerRadius: Prism.cardRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Prism.cardRadius, style: .continuous)
                    .strokeBorder(Prism.hairline, lineWidth: 1)
            )
    }
}

extension View {
    func prismGradientCard(_ gradient: LinearGradient, padding: CGFloat = 16) -> some View {
        modifier(PrismGradientCardStyle(gradient: gradient, padding: padding))
    }
    func prismSurfaceCard(padding: CGFloat = 16) -> some View {
        modifier(PrismSurfaceCardStyle(padding: padding))
    }
}

// MARK: - Small shared pieces

/// Tracked section label. Defaults to the muted ink; pass `.white` on a box.
struct PrismOverline: View {
    let text: String
    var tint: Color = Prism.inkSoft
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .default).weight(.semibold))
            .tracking(1.4)
            .foregroundStyle(tint)
    }
}

/// The round accent "+" button on the canvas.
struct PrismPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 42, height: 42)
                .background(Prism.accent, in: Circle())
                .shadow(color: Prism.accent.opacity(0.4), radius: 10, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

/// A neutral round icon button (e.g. settings) on the canvas.
struct PrismIconButton: View {
    let systemImage: String
    var accessibilityLabel: String
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(Prism.ink)
                .frame(width: 42, height: 42)
                .background(Prism.surface, in: Circle())
                .overlay(Circle().strokeBorder(Prism.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

/// Filled accent capsule for sheet / empty-state primary actions.
struct PrismPrimaryButton: View {
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
            .background(Prism.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Segmented pill control (active = accent), for the Spent / Budget toggle.
struct PrismPills<T: Hashable>: View {
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
                        .foregroundStyle(on ? .white : Prism.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background { if on { Capsule().fill(Prism.accent) } }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Prism.well, in: Capsule())
    }
}
