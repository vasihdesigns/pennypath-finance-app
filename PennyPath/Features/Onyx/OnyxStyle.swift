//
//  OnyxStyle.swift
//  PennyPath
//
//  Style kit for the "Onyx" reskin (Developer Mode only): the "espresso" concept
//  with translucent floating cards. Adaptive — dark mode is an espresso→black
//  canvas with light translucent cards; light mode is a cream canvas with dark
//  translucent cards. Follows the app's Appearance setting.
//

import SwiftUI

enum Onyx {
    static let accent = Color.adaptive(light: 0xA66E22, dark: 0xDCA658)   // amber / bronze
    static let cardRadius: CGFloat = 24

    // Text (adaptive)
    static let onCanvas = Color.adaptive(light: 0x2A1D12, dark: 0xF6EDE1)
    static let onCanvasSoft = Color.adaptive(light: 0x6E5A3E, dark: 0xCBBBA6)
    static let primary = Color.adaptive(light: 0x241A0E, dark: 0xF4ECDD)   // on cards
    static let secondary = Color.adaptive(light: 0x6E5C42, dark: 0xCBBBA6)

    // Translucent panel — light fill on the dark canvas, dark fill on the light.
    static func fill(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color(hex: 0xE9CEA6).opacity(0.14) : Color(hex: 0x6B4E2A).opacity(0.12)
    }
    static func stroke(_ scheme: ColorScheme) -> Color {
        scheme == .dark ? Color.white.opacity(0.14) : Color.black.opacity(0.12)
    }
}

// MARK: - The canvas with a warm glow (adaptive)

struct OnyxBackground: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.adaptive(light: 0xFBF4E8, dark: 0x322417),
                         Color.adaptive(light: 0xF0E2CC, dark: 0x1D150D),
                         Color.adaptive(light: 0xE2CDA8, dark: 0x0C0805)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            RadialGradient(
                colors: [Color.adaptive(light: 0xF0CE92, dark: 0xD6A05A).opacity(0.30), .clear],
                center: UnitPoint(x: 0.22, y: 0.10), startRadius: 8, endRadius: 380)
        }
        .ignoresSafeArea()
    }
}

// MARK: - Translucent surface

private struct OnyxGlassStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var padding: CGFloat
    var radius: CGFloat
    var interactive: Bool
    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: radius, style: .continuous)
        content
            .padding(padding)
            .background(Onyx.fill(scheme), in: shape)
            .overlay(shape.strokeBorder(Onyx.stroke(scheme), lineWidth: 1))
            .shadow(color: .black.opacity(0.22), radius: 12, y: 6)
    }
}

private struct OnyxGlassCircleStyle: ViewModifier {
    @Environment(\.colorScheme) private var scheme
    var interactive: Bool
    func body(content: Content) -> some View {
        content
            .background(Onyx.fill(scheme), in: Circle())
            .overlay(Circle().strokeBorder(Onyx.stroke(scheme), lineWidth: 1))
            .shadow(color: .black.opacity(0.22), radius: 10, y: 5)
    }
}

extension View {
    func onyxGlass(padding: CGFloat = 16, radius: CGFloat = Onyx.cardRadius, interactive: Bool = false) -> some View {
        modifier(OnyxGlassStyle(padding: padding, radius: radius, interactive: interactive))
    }
    func onyxGlassCircle(interactive: Bool = true) -> some View {
        modifier(OnyxGlassCircleStyle(interactive: interactive))
    }
}

// MARK: - Header pill

struct OnyxGlassPill: View {
    let label: String
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(label)
                .font(.system(size: 17))
                .foregroundStyle(Onyx.onCanvas)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, minHeight: 50, alignment: .topLeading)
        .onyxGlass(padding: 16, radius: 18)
    }
}

// MARK: - Floating + button

struct OnyxPlusButton: View {
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: "plus")
                .font(.system(size: 24, weight: .bold))
                .foregroundStyle(Onyx.onCanvas)
                .frame(width: 62, height: 62)
                .onyxGlassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add")
    }
}

// MARK: - A glass icon button (e.g. settings)

struct OnyxGlassCircleButton: View {
    let systemImage: String
    var accessibilityLabel: String
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Onyx.onCanvas)
                .frame(width: 42, height: 42)
                .onyxGlassCircle()
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
    }
}

// MARK: - One asset (category) as a translucent card

struct OnyxSubItem: Identifiable {
    let id = UUID()
    let name: String
    let value: String
}

struct OnyxAsset: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let value: String
    let date: String
    let items: [OnyxSubItem]
}

struct OnyxAssetCard: View {
    @Environment(\.colorScheme) private var scheme
    let asset: OnyxAsset
    let isExpanded: Bool
    var onToggle: () -> Void

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
        .onyxGlass(padding: 18, interactive: true)
    }

    private var header: some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(asset.title)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(Onyx.primary)
                Text(asset.subtitle)
                    .font(.system(size: 13))
                    .foregroundStyle(Onyx.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 8)
            VStack(alignment: .trailing, spacing: 4) {
                Text(asset.value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundStyle(Onyx.primary)
                HStack(spacing: 5) {
                    Text(asset.date)
                        .font(.system(size: 13))
                        .foregroundStyle(Onyx.secondary)
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Onyx.secondary)
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
            }
        }
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(asset.title), \(asset.value), \(asset.subtitle), \(asset.date)")
        .accessibilityHint(asset.items.isEmpty ? "" : (isExpanded ? "Collapse" : "Expand to see accounts"))
    }

    private func subRow(_ item: OnyxSubItem) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let base = scheme == .dark ? Color.white : Color.black
        return HStack(spacing: 8) {
            Text(item.name)
                .font(.system(size: 16))
                .foregroundStyle(Onyx.primary)
            Spacer(minLength: 8)
            Text(item.value)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(Onyx.primary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(base.opacity(scheme == .dark ? 0.10 : 0.05), in: shape)
        .overlay(shape.strokeBorder(base.opacity(scheme == .dark ? 0.16 : 0.12), lineWidth: 1))
    }
}
