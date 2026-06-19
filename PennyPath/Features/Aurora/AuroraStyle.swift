//
//  AuroraStyle.swift
//  PennyPath
//
//  Style kit for the "Aurora" reskin (Developer Mode only): a cosmic,
//  night-sky look — deep indigo space, drifting aurora glows, a quiet
//  starfield, and glassy cards with luminous gradient edges. Rounded
//  type throughout. Only the look changes; every feature is the real one.
//

import SwiftUI

enum Aurora {

    // MARK: Sky

    /// The deep space backdrop. Aurora is always dark — it's night up here.
    static let sky = Color(hex: 0x0A0B14)
    static let skyHigh = Color(hex: 0x141633)

    // MARK: Glass

    static let glass = Color.white.opacity(0.055)
    static let glassPressed = Color.white.opacity(0.10)
    static let hairline = Color.white.opacity(0.08)

    // MARK: Ink

    static let ink = Color(hex: 0xF1F2FF)
    static let inkSoft = Color(hex: 0x9DA3C9)
    static let inkFaint = Color(hex: 0x5E6388)

    // MARK: Lights

    /// The signature aurora mint — growth, assets, good news.
    static let mint = Color(hex: 0x5FE8C2)
    /// Deep violet — the brand's second voice.
    static let violet = Color(hex: 0x8E7CF8)
    /// Warm nebula pink — spending.
    static let pink = Color(hex: 0xF47BB4)
    /// Star gold — goals and wins.
    static let gold = Color(hex: 0xF6C667)
    /// Red-dwarf coral — debts and overspend.
    static let coral = Color(hex: 0xFB7185)

    static let cardRadius: CGFloat = 24

    /// Colors for spending categories, biggest slice first.
    static let chartPalette: [Color] = [pink, violet, mint, gold, coral, inkSoft]

    /// The signature mint → violet sweep used on hero numbers and buttons.
    static var beam: LinearGradient {
        LinearGradient(colors: [mint, violet],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }
}

// MARK: - Type (rounded, scaled with Dynamic Type)

extension Font {
    /// Big rounded display headings.
    static func auroraDisplay(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .rounded)
    }
    /// Money numbers: rounded with lined-up digits.
    static func auroraAmount(_ size: CGFloat, weight: Font.Weight = .bold) -> Font {
        .system(size: Font.scaled(size), weight: weight, design: .rounded).monospacedDigit()
    }
}

// MARK: - The sky itself

/// Deep space with two slow-breathing aurora glows and a fixed starfield.
/// Sits behind every Aurora screen.
struct AuroraSky: View {
    var dimmed = false
    @State private var drift = false

    var body: some View {
        ZStack {
            Aurora.sky

            // Two soft nebula glows that drift very slowly.
            Circle()
                .fill(Aurora.violet.opacity(dimmed ? 0.16 : 0.24))
                .frame(width: 420, height: 420)
                .blur(radius: 110)
                .offset(x: drift ? -110 : -40, y: drift ? -220 : -300)
            Circle()
                .fill(Aurora.mint.opacity(dimmed ? 0.10 : 0.16))
                .frame(width: 360, height: 360)
                .blur(radius: 100)
                .offset(x: drift ? 150 : 90, y: drift ? -40 : 60)

            AuroraStars()
        }
        .ignoresSafeArea()
        .onAppear {
            withAnimation(.easeInOut(duration: 9).repeatForever(autoreverses: true)) {
                drift = true
            }
        }
    }
}

/// A deterministic scatter of tiny stars (seeded, so it never re-rolls).
private struct AuroraStars: View {
    var body: some View {
        Canvas { context, size in
            var seed: UInt64 = 0x5EED_1A7E
            func next() -> Double {
                // xorshift64 — cheap, repeatable sparkle.
                seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17
                return Double(seed % 10_000) / 10_000
            }
            for _ in 0..<90 {
                let x = next() * size.width
                let y = next() * size.height
                let r = 0.4 + next() * 1.1
                let alpha = 0.12 + next() * 0.5
                context.fill(
                    Path(ellipseIn: CGRect(x: x, y: y, width: r * 2, height: r * 2)),
                    with: .color(.white.opacity(alpha))
                )
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Glass cards

private struct AuroraCardStyle: ViewModifier {
    var padding: CGFloat
    var glow: Color?

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                Aurora.glass,
                in: RoundedRectangle(cornerRadius: Aurora.cardRadius, style: .continuous)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Aurora.cardRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.22), .white.opacity(0.03)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
            .shadow(color: (glow ?? .black).opacity(glow == nil ? 0.35 : 0.25),
                    radius: 18, y: 8)
    }
}

extension View {
    /// Aurora's frosted-glass card. Pass `glow:` to give it a colored halo.
    func auroraCard(padding: CGFloat = 20, glow: Color? = nil) -> some View {
        modifier(AuroraCardStyle(padding: padding, glow: glow))
    }
}

// MARK: - Small shared pieces

/// The uppercase, letterspaced section label ("NET WORTH", "QUESTS"…).
struct AuroraOverline: View {
    let text: String
    var tint: Color = Aurora.inkSoft
    var body: some View {
        Text(text.uppercased())
            .font(.system(.caption, design: .rounded).weight(.bold))
            .tracking(2.4)
            .foregroundStyle(tint)
    }
}

/// The glowing capsule call-to-action used across Aurora.
struct AuroraBeamButton: View {
    let title: String
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .foregroundStyle(Aurora.sky)
                .padding(.vertical, 14)
                .padding(.horizontal, 28)
                .background(Aurora.beam, in: Capsule())
                .shadow(color: Aurora.mint.opacity(0.45), radius: 14, y: 4)
        }
        .buttonStyle(.plain)
    }
}
