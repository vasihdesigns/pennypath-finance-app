//
//  MidnightStyle.swift
//  PennyPath
//
//  Style kit for the "Midnight" reskin (Developer Mode only): the Ember stacked
//  layout in a midnight-blue palette. Adaptive — dark mode is a navy→light-blue
//  canvas with light→dark cards; light mode is a pale-blue canvas with the ramp
//  inverted. Follows the app's Appearance setting.
//

import SwiftUI

enum Midnight {

    // MARK: Canvas (adaptive)

    static let canvas = LinearGradient(
        colors: [Color.adaptive(light: 0xF7FAFE, dark: 0x101A2E),
                 Color.adaptive(light: 0xEAF1FA, dark: 0x213A60),
                 Color.adaptive(light: 0xD6E2F2, dark: 0x4C6C9C),
                 Color.adaptive(light: 0xBFD0E8, dark: 0xB4C4DC)],
        startPoint: .top, endPoint: .bottom)

    // MARK: Card ramp (inverts between modes)

    static let cardLight = Color.adaptive(light: 0x2A3D5E, dark: 0xDFE7F1)
    static let cardMid = Color.adaptive(light: 0x3A4E72, dark: 0xC4D2E6)
    static let cardDark = Color.adaptive(light: 0xD2DEF0, dark: 0x47597C)
    static let cardDeepest = Color.adaptive(light: 0xEAF1FB, dark: 0x1A2740)

    static let cardLightDeep = Color.adaptive(light: 0x1E2E48, dark: 0xC6D2E4)
    static let cardMidDeep = Color.adaptive(light: 0x2C3E5C, dark: 0xA8BAD4)
    static let cardDarkDeep = Color.adaptive(light: 0xBECEE6, dark: 0x35455F)
    static let cardDeepestDeep = Color.adaptive(light: 0xD8E4F4, dark: 0x0E1828)

    // MARK: Text on the canvas

    static let onCanvas = Color.adaptive(light: 0x16233B, dark: 0xF0F4FA)
    static let onCanvasSoft = Color.adaptive(light: 0x4E5E7C, dark: 0xCAD6E6).opacity(0.95)

    // MARK: Furniture

    static let accent = Color.adaptive(light: 0x2E6FC0, dark: 0x6FA0E6)   // blue / sky
    static let tabInactive = Color.adaptive(light: 0x556580, dark: 0xAEBCD0)
    static let plus = Color.adaptive(light: 0x16233B, dark: 0xDFE7F1)
    static let plusInk = Color.adaptive(light: 0xDFE7F1, dark: 0x16233B)

    static let cardRadius: CGFloat = 28
}

// MARK: - One asset row in the fanned stack

struct MidnightSubItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
}

struct MidnightAsset: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let value: String
    let date: String
    let fill: Color
    let fillBottom: Color
    let primary: Color
    let secondary: Color
    /// True for cards dark in DARK mode (they invert in light mode).
    let isDark: Bool
    let items: [MidnightSubItem]
}

struct MidnightAssetCard: View {
    @Environment(\.colorScheme) private var scheme
    let asset: MidnightAsset
    let isExpanded: Bool
    let isLast: Bool
    var tuck: CGFloat = 72
    var onToggle: () -> Void

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
            let shape = RoundedRectangle(cornerRadius: Midnight.cardRadius, style: .continuous)
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
            RoundedRectangle(cornerRadius: Midnight.cardRadius, style: .continuous)
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

    private func subRow(_ item: MidnightSubItem) -> some View {
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
        .overlay(shape.strokeBorder(cardIsDark ? .white.opacity(0.22) : .black.opacity(0.18), lineWidth: 1))
    }
}

// MARK: - Header pill

struct MidnightGlassPill: View {
    @Environment(\.colorScheme) private var scheme
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Midnight.onCanvasSoft)
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

struct MidnightPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(Midnight.plusInk)
                .frame(width: 64, height: 64)
                .background(Midnight.plus, in: Circle())
                .shadow(color: .black.opacity(0.28), radius: 10, y: 5)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}
