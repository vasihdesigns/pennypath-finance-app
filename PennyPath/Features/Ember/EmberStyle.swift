//
//  EmberStyle.swift
//  PennyPath
//
//  Style kit for the Ember shell — the app's main UI. A fanned stack of cards
//  in a bronze palette. Adaptive — dark mode is an espresso→champagne canvas
//  with cream→espresso cards; light mode is a champagne canvas with the ramp
//  inverted. Follows the app's Appearance setting. Only the look is Ember's;
//  every screen reads the real store and reuses the real forms and services.
//

import SwiftUI

enum Ember {

    // MARK: Canvas (adaptive)

    static let canvas = LinearGradient(
        colors: [Color.adaptive(light: 0xFBF6EE, dark: 0x2A1D14),
                 Color.adaptive(light: 0xF3E9D6, dark: 0x4D3A2A),
                 Color.adaptive(light: 0xE8D5B8, dark: 0x8B6F53),
                 Color.adaptive(light: 0xDAC4A2, dark: 0xCDB89B)],
        startPoint: .top, endPoint: .bottom)

    // MARK: Text on the canvas

    static let onCanvas = Color.adaptive(light: 0x2A1D14, dark: 0xFBF4EA)
    static let onCanvasSoft = Color.adaptive(light: 0x6B5A42, dark: 0xEADFCE).opacity(0.95)

    // MARK: Furniture

    static let accent = Color.adaptive(light: 0xA6661F, dark: 0xD79A45)   // bronze / gold
    /// A muted taupe used in place of the gold accent on the Expenses & Goals
    /// screens (data bars, meters, selected controls) — softer and more premium.
    static let accentSoft = Color(hex: 0xA69474)
    static let tabInactive = Color.adaptive(light: 0x6E5C42, dark: 0xC9BCA8)
    /// Money leaving / over-budget — a restrained terracotta on the canvas.
    static let spend = Color.adaptive(light: 0xB23B2E, dark: 0xF0917F)
    /// Under-budget / positive — a calm green.
    static let good = Color.adaptive(light: 0x2E7D5B, dark: 0x6FD3A6)
    static let plus = Color.adaptive(light: 0x2B1F14, dark: 0xF2E9DB)
    static let plusInk = Color.adaptive(light: 0xF2E9DB, dark: 0x2B1F14)

    static let cardRadius: CGFloat = 28

    // MARK: Smoked-glass surfaces (the neutral boxes that sit on the canvas)

    /// Dark, translucent fill — reads as smoked glass over the bronze canvas in
    /// both modes, rather than a white-tinted lift.
    static func glassFill(dark: Bool) -> Color { Color.black.opacity(dark ? 0.32 : 0.10) }
    /// Hairline rim for those boxes: a faint light lip in the dark, a soft dark
    /// edge in the light.
    static func glassStroke(dark: Bool) -> Color {
        (dark ? Color.white : Color.black).opacity(dark ? 0.12 : 0.10)
    }
}

// MARK: - Money kinds (how real accounts group into Ember's deck)

/// The five net-worth groups Ember fans into a deck of cards. Each maps onto a
/// real `AccountCategory` so net-worth maths (assets add, debts subtract) stays
/// correct, and carries the bronze gradient that paints its card.
enum EmberMoneyKind: String, CaseIterable, Identifiable {
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
    static func of(_ category: AccountCategory) -> EmberMoneyKind {
        switch category {
        case .cash, .savings: return .cash
        case .investment: return .investment
        case .property: return .property
        case .otherAsset: return .receivable
        case .creditCard, .loan, .otherDebt: return .liability
        }
    }

    // MARK: Card palette — one cohesive deep-bronze deck, cream text on every card.

    /// Top colour of the card's gradient. A ramp from warm bronze (Cash) down to
    /// espresso (Liability), so the stacked deck reads as one bronze family.
    var fill: Color {
        switch self {
        case .cash:       return Color(hex: 0x8A6749)
        case .investment: return Color(hex: 0x6F5234)
        case .property:   return Color(hex: 0x5A4029)
        case .receivable: return Color(hex: 0x49341F)
        case .liability:  return Color(hex: 0x2B1F14)
        }
    }

    /// Bottom colour of the card's gradient.
    var fillBottom: Color {
        switch self {
        case .cash:       return Color(hex: 0x73553A)
        case .investment: return Color(hex: 0x5B4228)
        case .property:   return Color(hex: 0x48311F)
        case .receivable: return Color(hex: 0x392819)
        case .liability:  return Color(hex: 0x1A120A)
        }
    }

    /// Primary text/number colour — warm cream on every card.
    var primary: Color { Color(hex: 0xFBF4EA) }

    /// Secondary (subtitle) colour — a muted warm tan that reads on the bronze.
    var secondary: Color {
        switch self {
        case .cash:       return Color(hex: 0xDDCBAA)
        case .investment: return Color(hex: 0xD3BE99)
        case .property:   return Color(hex: 0xCBB48C)
        case .receivable: return Color(hex: 0xC4AC83)
        case .liability:  return Color(hex: 0xC8B7A2)
        }
    }
}

// MARK: - Header (title + settings gear) shared by every Ember screen

struct EmberHeader: View {
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
                .foregroundStyle(Ember.onCanvas)
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
                .foregroundStyle(Ember.onCanvas)
                .frame(width: 42, height: 42)
                .background(Ember.glassFill(dark: scheme == .dark), in: Circle())
                .overlay(Circle().strokeBorder(Ember.glassStroke(dark: scheme == .dark), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

// MARK: - Neutral content panel (Expenses / Goals / Insights cards)

private struct EmberPanelStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Ember.glassFill(dark: scheme == .dark),
                        in: RoundedRectangle(cornerRadius: radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: radius, style: .continuous)
                    .strokeBorder(Ember.glassStroke(dark: scheme == .dark), lineWidth: 1)
            )
    }
}

extension View {
    /// A calm translucent card that reads on the bronze canvas. Use for the
    /// non-deck screens (Expenses, Goals, Insights).
    func emberPanel(padding: CGFloat = 18, radius: CGFloat = 22) -> some View {
        modifier(EmberPanelStyle(padding: padding, radius: radius))
    }
}

// MARK: - Header pill (a labelled total)

struct EmberGlassPill: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    let value: String
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Ember.onCanvasSoft)
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(Ember.onCanvas)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, minHeight: 52, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Ember.glassFill(dark: scheme == .dark),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(Ember.glassStroke(dark: scheme == .dark), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(label), \(value)")
    }
}

// MARK: - Floating + button

struct EmberPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Ember.plusInk)
                .frame(width: 64, height: 64)
                .background(Ember.plus, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}
