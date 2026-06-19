//
//  SlateStyle.swift
//  PennyPath
//
//  Style kit for the "Slate" reskin (Developer Mode only): the Ember stacked
//  layout in a charcoal palette. Adaptive — dark mode is a charcoal→silver
//  canvas with light→dark cards; light mode is a white canvas with the ramp
//  inverted (dark→light cards). Follows the app's Appearance setting.
//

import SwiftUI

enum Slate {

    // MARK: Canvas (adaptive)

    static let canvas = LinearGradient(
        colors: [Color.adaptive(light: 0xFAFAFB, dark: 0x1C1C20),
                 Color.adaptive(light: 0xF0F0F3, dark: 0x38383F),
                 Color.adaptive(light: 0xE2E2E8, dark: 0x6E6E78),
                 Color.adaptive(light: 0xCFCFD8, dark: 0xC0C0CA)],
        startPoint: .top, endPoint: .bottom)

    // MARK: Card ramp — inverts between modes (Cash light in dark, dark in light)

    static let cardLight = Color.adaptive(light: 0x35353B, dark: 0xEAEAEE)   // Cash
    static let cardMid = Color.adaptive(light: 0x47474E, dark: 0xD0D0D7)     // Investment
    static let cardDark = Color.adaptive(light: 0xD4D4DA, dark: 0x6C6C76)    // Property
    static let cardDeepest = Color.adaptive(light: 0xEDEDF0, dark: 0x2A2A30) // Liability

    static let cardLightDeep = Color.adaptive(light: 0x26262B, dark: 0xD6D6DD)
    static let cardMidDeep = Color.adaptive(light: 0x35353B, dark: 0xB7B7C0)
    static let cardDarkDeep = Color.adaptive(light: 0xC2C2CA, dark: 0x52525C)
    static let cardDeepestDeep = Color.adaptive(light: 0xDCDCE2, dark: 0x1A1A1E)

    // MARK: Text on the canvas (adaptive)

    static let onCanvas = Color.adaptive(light: 0x1C1C20, dark: 0xF4F4F6)
    static let onCanvasSoft = Color.adaptive(light: 0x55555C, dark: 0xD8D8DE).opacity(0.95)

    // MARK: Furniture

    static let accent = Color.adaptive(light: 0x4C6E96, dark: 0x86A6CE)   // steel blue
    static let tabInactive = Color.adaptive(light: 0x55555C, dark: 0xB4B4BC)
    static let plus = Color.adaptive(light: 0x2A2A30, dark: 0xEAEAEE)
    static let plusInk = Color.adaptive(light: 0xF4F4F6, dark: 0x2A2A30)

    static let cardRadius: CGFloat = 28
}

// MARK: - One asset row in the fanned stack

struct SlateSubItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
}

struct SlateAsset: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let value: String
    let date: String
    let fill: Color
    let fillBottom: Color
    let primary: Color
    let secondary: Color
    /// True for cards that are dark in DARK mode (they invert in light mode).
    let isDark: Bool
    let items: [SlateSubItem]
}

struct SlateAssetCard: View {
    @Environment(\.colorScheme) private var scheme
    let asset: SlateAsset
    let isExpanded: Bool
    let isLast: Bool
    var tuck: CGFloat = 72
    var onToggle: () -> Void

    /// Whether the card reads dark right now (isDark in dark mode; inverted in light).
    private var cardIsDark: Bool { (scheme == .dark) == asset.isDark }

    var body: some View {
        VStack(spacing: 0) {
            Button(action: onToggle) { header }
                .buttonStyle(.plain)

            if isExpanded && !asset.items.isEmpty {
                VStack(spacing: 8) {
                    ForEach(asset.items) { item in
                        subRow(item)
                    }
                }
                .padding(.top, 12)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 18)
        .padding(.bottom, isLast ? 24 : tuck)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            let shape = RoundedRectangle(cornerRadius: Slate.cardRadius, style: .continuous)
            shape.fill(LinearGradient(
                colors: [asset.fill, asset.fillBottom],
                startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(
                    shape.fill(LinearGradient(
                        colors: [.white.opacity(0.20), .white.opacity(0.04), .clear],
                        startPoint: .topLeading, endPoint: .bottomTrailing))
                )
        }
        .overlay(
            RoundedRectangle(cornerRadius: Slate.cardRadius, style: .continuous)
                .strokeBorder(LinearGradient(
                    colors: [.white.opacity(0.55), .white.opacity(0.14), .white.opacity(0.04)],
                    startPoint: .top, endPoint: .bottom),
                    lineWidth: 1.2)
        )
        .shadow(color: .black.opacity(0.18), radius: 7, y: -3)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(asset.primary)
                Text(asset.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(asset.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(asset.value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(asset.primary)
                HStack(spacing: 5) {
                    Text(asset.date)
                        .font(.system(size: 13))
                        .foregroundStyle(asset.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(asset.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(asset.title), \(asset.value), \(asset.subtitle), \(asset.date)")
        .accessibilityHint(asset.items.isEmpty ? "" : (isExpanded ? "Collapse" : "Expand to see accounts"))
    }

    private func subRow(_ item: SlateSubItem) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        return HStack(spacing: 8) {
            Text(item.name)
                .font(.system(size: 16))
                .foregroundStyle(asset.primary)
            Spacer(minLength: 8)
            Text(item.value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(asset.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white.opacity(cardIsDark ? 0.12 : 0.45), in: shape)
        // Light stroke on dark cards, dark stroke on light cards.
        .overlay(shape.strokeBorder(cardIsDark ? .white.opacity(0.22) : .black.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Header pill

struct SlateGlassPill: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Slate.onCanvasSoft)
            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(maxWidth: .infinity, minHeight: 66, alignment: .topLeading)
        .background((scheme == .dark ? Color.white : Color.black).opacity(0.06),
                    in: RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder((scheme == .dark ? Color.white : Color.black).opacity(0.16), lineWidth: 1)
        )
    }
}

// MARK: - Floating + button

struct SlatePlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Slate.plusInk)
                .frame(width: 64, height: 64)
                .background(Slate.plus, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}
