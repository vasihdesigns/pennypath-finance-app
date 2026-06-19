//
//  SummitStyle.swift
//  PennyPath
//
//  Style kit for the "Summit" reskin (Developer Mode only): a calm, premium,
//  editorial look for people serious about building wealth. Warm "paper"
//  canvas in light, deep charcoal at night; serif screen titles like a private
//  statement; one confident growth accent (emerald) and a milestone gold. The
//  Net Worth screen is the star and milestones are front and centre. Only the
//  look changes — every feature reuses the real models, forms and services.
//

import SwiftUI

enum Summit {

    // MARK: Surfaces

    /// Screen background — warm paper by day, near-black by night.
    static let canvas = Color.adaptive(light: 0xF7F5F0, dark: 0x0F1012)
    static let card = Color.adaptive(light: 0xFFFFFF, dark: 0x191B1E)
    static let well = Color.adaptive(light: 0xF0EEE7, dark: 0x232529)
    static let hairline = Color.adaptive(light: 0xE7E4DB, dark: 0x2D2F34)

    // MARK: Ink

    static let ink = Color.adaptive(light: 0x1A1B1E, dark: 0xF2F1EE)
    static let inkSoft = Color.adaptive(light: 0x6E6C66, dark: 0x9A988F)
    static let inkFaint = Color.adaptive(light: 0xA8A59D, dark: 0x66645D)

    // MARK: Accents — emerald for growth, gold for milestones

    /// The signature growth colour. Net worth, gains, the live tab.
    static let accent = Color.adaptive(light: 0x10805B, dark: 0x3BD89B)
    static let accentSoft = Color.adaptive(light: 0xE2F1EA, dark: 0x16322A)
    /// Milestones and achievements.
    static let gold = Color.adaptive(light: 0xB0801F, dark: 0xE7BE5C)
    static let goldSoft = Color.adaptive(light: 0xF4EBD6, dark: 0x2E2716)
    /// Money that leaves / debts / down moves. A restrained terracotta.
    static let down = Color.adaptive(light: 0xB04A36, dark: 0xE0876B)

    static let radius: CGFloat = 20

    // MARK: A colour per money kind (composition + lists)

    static func color(for category: AccountCategory) -> Color {
        switch category {
        case .cash:       return Color.adaptive(light: 0x2BA86E, dark: 0x46D69B)
        case .savings:    return Color.adaptive(light: 0x1E8C8C, dark: 0x37C2BE)
        case .investment: return Color.adaptive(light: 0x6E59C9, dark: 0x9A86F0)
        case .property:   return Color.adaptive(light: 0x3B7BD0, dark: 0x6BA0EE)
        case .otherAsset: return Color.adaptive(light: 0x8A93B5, dark: 0xA8B0CE)
        case .creditCard: return Color.adaptive(light: 0xB66A57, dark: 0xDB9482)
        case .loan:       return Color.adaptive(light: 0xA8806B, dark: 0xC79F8A)
        case .otherDebt:  return Color.adaptive(light: 0x9AA0AE, dark: 0x868C9A)
        }
    }

    /// Palette for spending categories, biggest slice first.
    static let spendPalette: [Color] = [
        Color.adaptive(light: 0x6E59C9, dark: 0x9A86F0),
        Color.adaptive(light: 0x3B7BD0, dark: 0x6BA0EE),
        Color.adaptive(light: 0x1E8C8C, dark: 0x37C2BE),
        Color.adaptive(light: 0x2BA86E, dark: 0x46D69B),
        Color.adaptive(light: 0xB0801F, dark: 0xE7BE5C),
        Color.adaptive(light: 0x8A93B5, dark: 0xA8B0CE)
    ]
}

// MARK: - Type (editorial serif titles, monospaced money)

extension Font {
    /// Screen titles and the wordmark — a refined serif, like a statement.
    static func summitSerif(_ size: CGFloat, weight: Font.Weight = .semibold) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .serif)
    }
    /// Plain professional sans for labels and body.
    static func summitText(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: Font.scaled(size), weight: weight)
    }
    /// Big money numbers — sans with aligned, monospaced digits.
    static func summitNumber(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight).monospacedDigit()
    }
}

// MARK: - Card surface

private struct SummitCardStyle: ViewModifier {
    var padding: CGFloat
    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(Summit.card, in: RoundedRectangle(cornerRadius: Summit.radius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: Summit.radius, style: .continuous)
                    .strokeBorder(Summit.hairline, lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, y: 4)
    }
}

extension View {
    func summitCard(padding: CGFloat = 18) -> some View {
        modifier(SummitCardStyle(padding: padding))
    }
}

// MARK: - Small shared pieces

/// Tracked uppercase section label.
struct SummitOverline: View {
    let text: String
    var tint: Color = Summit.inkFaint
    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .semibold))
            .tracking(1.5)
            .foregroundStyle(tint)
    }
}

/// The pinned top bar every Summit screen shares: a serif title on the left,
/// an optional privacy eye, an optional round add button, and the settings
/// gear in the top-right corner.
struct SummitTopBar: View {
    let title: String
    /// When provided, shows an eye toggle that hides/shows money app-wide.
    var privacy: Binding<Bool>? = nil
    var onAdd: (() -> Void)? = nil
    var onSettings: () -> Void

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Text(title)
                .font(.summitSerif(27, weight: .semibold))
                .foregroundStyle(Summit.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Spacer(minLength: 8)
            if let privacy {
                roundButton(symbol: privacy.wrappedValue ? "eye.slash" : "eye",
                            tint: Summit.inkSoft,
                            label: privacy.wrappedValue ? "Show amounts" : "Hide amounts") {
                    privacy.wrappedValue.toggle()
                }
            }
            if let onAdd {
                roundButton(symbol: "plus", tint: Summit.ink, label: "Add", action: onAdd)
            }
            roundButton(symbol: "gearshape", tint: Summit.inkSoft, label: "Settings", action: onSettings)
        }
    }

    private func roundButton(symbol: String, tint: Color, label: String, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 38, height: 38)
                .background(Summit.card, in: Circle())
                .overlay(Circle().strokeBorder(Summit.hairline, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

/// Filled emerald capsule for the main action in an empty state.
struct SummitPrimaryButton: View {
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
                Text(title).font(.system(size: 16, weight: .semibold))
            }
            .foregroundStyle(.white)
            .padding(.vertical, 15)
            .padding(.horizontal, 26)
            .background(Summit.accent, in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// A soft, full-width "+ Add …" row used at the foot of cards.
struct SummitAddRow: View {
    let title: String
    var tint: Color = Summit.accent
    var action: () -> Void
    var body: some View {
        Button {
            Haptics.tap()
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "plus").font(.system(size: 13, weight: .bold))
                Text(title).font(.system(size: 14, weight: .semibold))
            }
            .foregroundStyle(tint)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(tint.opacity(0.12), in: Capsule())
        }
        .buttonStyle(.plain)
    }
}

/// Segmented pill control (active = solid emerald).
struct SummitSegmented<T: Hashable>: View {
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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(on ? .white : Summit.inkSoft)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background { if on { Capsule().fill(Summit.accent) } }
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(Summit.well, in: Capsule())
    }
}

/// A thin progress meter that matches the Summit palette.
struct SummitMeter: View {
    var value: Double                  // 0…1
    var tint: Color = Summit.accent
    var track: Color = Summit.well
    var height: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(track)
                Capsule().fill(tint)
                    .frame(width: max(height, min(1, max(0, value)) * geo.size.width))
            }
        }
        .frame(height: height)
        .accessibilityValue(percentText(value))
    }
}

/// One slice of the composition bar.
struct SummitSegment: Identifiable {
    let id = UUID()
    let color: Color
    let value: Double
    let label: String
}

/// A single slim horizontal bar split into proportional colour segments —
/// the quiet visual summary of what you're made of, or where money went.
struct SummitCompositionBar: View {
    let segments: [SummitSegment]
    var height: CGFloat = 12
    private var total: Double { max(segments.reduce(0) { $0 + $1.value }, 0.0001) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 0) {
                ForEach(segments) { seg in
                    seg.color
                        .frame(width: CGFloat(seg.value / total) * geo.size.width)
                }
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityHidden(true)
    }
}

// MARK: - Deletable row

/// Wraps a row so a plain tap opens it for editing and a long-press offers a
/// Delete that always confirms first — so a stray tap can never destroy real
/// data. Tap + context menu only (no custom drag), so it never competes with
/// the list's own scrolling. Each item's edit screen also carries a Delete
/// button, giving two clear, safe ways to remove something.
struct SummitDeletableRow<Content: View>: View {
    var confirmTitle: String
    var confirmMessage: String
    var onEdit: () -> Void
    var onDelete: () -> Void
    @ViewBuilder var content: () -> Content

    @State private var showConfirm = false

    var body: some View {
        Button(action: onEdit) {
            content()
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(action: onEdit) { Label("Edit", systemImage: "pencil") }
            Button(role: .destructive) { showConfirm = true } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .confirmationDialog(confirmTitle, isPresented: $showConfirm, titleVisibility: .visible) {
            Button("Delete", role: .destructive) { onDelete() }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text(confirmMessage)
        }
    }
}
