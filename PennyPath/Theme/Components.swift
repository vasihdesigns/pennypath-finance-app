//
//  Components.swift
//  PennyPath
//
//  Small reusable building blocks so every screen looks and feels the same.
//

import SwiftUI
import UIKit

// MARK: - Haptics

enum Haptics {
    static func tap(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .light) {
        UIImpactFeedbackGenerator(style: style).impactOccurred()
    }
    static func success() {
        UINotificationFeedbackGenerator().notificationOccurred(.success)
    }
}

// MARK: - Emoji badge (the little rounded icon on each row)

struct EmojiBadge: View {
    let emoji: String
    var tint: Color = Theme.ink
    var size: CGFloat = 44

    var body: some View {
        Text(emoji)
            .font(.system(size: size * 0.48))
            .frame(width: size, height: size)
            .background(tint.opacity(0.14),
                        in: RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
    }
}

// MARK: - Section header

struct SectionHeader: View {
    let title: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title)
                .font(.display(20))
                .foregroundStyle(Theme.ink)
            Spacer()
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(Theme.inkSecondary)
            }
        }
    }
}

// MARK: - Stat tile (a small labelled number on a card)

struct StatTile: View {
    let label: String
    let value: String
    var tint: Color = Theme.ink
    var caption: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(label.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(0.5)
            Text(value)
                .font(.amount(24))
                .foregroundStyle(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            if let caption {
                Text(caption)
                    .font(.caption)
                    .foregroundStyle(Theme.inkTertiary)
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

// MARK: - Progress bar

struct ProgressBar: View {
    var value: Double          // 0...1
    var tint: Color
    var height: CGFloat = 10

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.well)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, value)) * geo.size.width)
            }
        }
        .frame(height: height)
        .accessibilityLabel("Progress")
        .accessibilityValue(percentText(value))
    }
}

// MARK: - Progress ring

struct ProgressRing: View {
    var value: Double          // 0...1
    var tint: Color
    var lineWidth: CGFloat = 12

    var body: some View {
        ZStack {
            Circle().stroke(Theme.well, lineWidth: lineWidth)
            Circle()
                .trim(from: 0, to: max(0.001, min(1, value)))
                .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.spring(duration: 0.5), value: value)
        }
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue(percentText(value))
    }
}

// MARK: - Split bar (assets vs debts in one bar)

struct SplitBar: View {
    var leading: Double
    var trailing: Double
    var leadingColor: Color = Theme.green
    var trailingColor: Color = Theme.red
    var height: CGFloat = 14

    private var total: Double { max(leading + trailing, 0.0001) }

    var body: some View {
        GeometryReader { geo in
            HStack(spacing: 3) {
                Capsule().fill(leadingColor)
                    .frame(width: CGFloat(leading / total) * geo.size.width)
                Capsule().fill(trailingColor)
            }
        }
        .frame(height: height)
        .clipShape(Capsule())
        .accessibilityElement()
        .accessibilityLabel("Own versus owe")
        .accessibilityValue("\(percentText(leading / total)) owned, \(percentText(trailing / total)) owed")
    }
}

// MARK: - Empty state

struct EmptyState: View {
    let emoji: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var tint: Color = Theme.ink
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: Theme.Space.md) {
            Text(emoji).font(.system(size: 52))
            Text(title)
                .font(.display(20))
                .foregroundStyle(Theme.ink)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(Theme.inkSecondary)
                .multilineTextAlignment(.center)
            if let actionTitle, let action {
                Button(actionTitle, action: action)
                    .buttonStyle(PrimaryButtonStyle(tint: tint))
                    .padding(.top, Theme.Space.sm)
                    .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, Theme.Space.xxl)
        .padding(.horizontal, Theme.Space.lg)
    }
}

// MARK: - Button styles

struct PrimaryButtonStyle: ButtonStyle {
    var tint: Color = Theme.ink
    var foreground: Color = Color(.systemBackground)

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(tint, in: Capsule())
            .opacity(configuration.isPressed ? 0.85 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

/// A soft, tinted button used for quick actions.
struct SoftButtonStyle: ButtonStyle {
    var tint: Color = Theme.ink

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(tint)
            .padding(.vertical, 12)
            .frame(maxWidth: .infinity)
            .background(tint.opacity(0.14), in: Capsule())
            .opacity(configuration.isPressed ? 0.7 : 1)
    }
}

// MARK: - Chip grid (pick one category)

/// Anything that can be shown as an emoji + title chip.
protocol Pickable: Identifiable, Hashable {
    var emoji: String { get }
    var title: String { get }
}

struct ChipGrid<Item: Pickable>: View {
    let items: [Item]
    @Binding var selection: Item
    var tint: Color = Theme.ink

    private let columns = [GridItem(.adaptive(minimum: 96), spacing: Theme.Space.sm)]

    var body: some View {
        LazyVGrid(columns: columns, spacing: Theme.Space.sm) {
            ForEach(items) { item in
                let selected = item == selection
                Button { selection = item } label: {
                    HStack(spacing: 6) {
                        Text(item.emoji)
                        Text(item.title)
                            .font(.subheadline.weight(.medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .padding(.horizontal, 8)
                    .background(selected ? tint.opacity(0.16) : Theme.well,
                                in: RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: Theme.Radius.chip, style: .continuous)
                            .strokeBorder(selected ? tint : .clear, lineWidth: 2)
                    )
                    .foregroundStyle(selected ? tint : Theme.ink)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Amount input field for forms

struct AmountField: View {
    let title: String
    @Binding var amount: Double
    var tint: Color = Theme.ink

    @FocusState private var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Space.sm) {
            Text(title.uppercased())
                .font(.caption.weight(.semibold))
                .foregroundStyle(Theme.inkSecondary)
                .tracking(0.5)
            HStack(spacing: 4) {
                Text(AppSettings.currencySymbol)
                    .font(.amount(32, weight: .semibold))
                    .foregroundStyle(Theme.inkSecondary)
                TextField("0", value: $amount, format: .number.precision(.fractionLength(0...2)))
                    .font(.amount(40))
                    .foregroundStyle(tint)
                    .keyboardType(.decimalPad)
                    .focused($focused)
            }
        }
        // The decimal pad has no return key; give it a Done button so the
        // typed amount is committed before tapping Save.
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { focused = false }.bold()
            }
        }
    }
}

// MARK: - Sparkline (a tiny trend line with a soft fill)

struct Sparkline: View {
    let values: [Double]
    var tint: Color = Theme.green
    var lineWidth: CGFloat = 2.5

    /// VoiceOver summary: where the trend started and where it is now.
    private var trendSummary: String {
        guard let first = values.first, let last = values.last, values.count >= 2 else {
            return "Not enough history yet"
        }
        if first == 0 { return "Now \(money(last))" }
        let change = (last - first) / abs(first)
        let direction = change >= 0 ? "up" : "down"
        return "\(direction) \(percentText(abs(change))), now \(money(last))"
    }

    var body: some View {
        GeometryReader { geo in
            let pts = points(in: geo.size)
            if pts.count >= 2 {
                ZStack {
                    areaPath(pts, height: geo.size.height)
                        .fill(LinearGradient(
                            colors: [tint.opacity(0.22), tint.opacity(0.02)],
                            startPoint: .top, endPoint: .bottom))
                    linePath(pts)
                        .stroke(tint, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    if let last = pts.last {
                        Circle().fill(tint)
                            .frame(width: lineWidth * 2.4, height: lineWidth * 2.4)
                            .position(last)
                    }
                }
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Trend")
        .accessibilityValue(trendSummary)
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard values.count >= 2 else { return [] }
        let minV = values.min() ?? 0
        let maxV = values.max() ?? 1
        let range = max(maxV - minV, 0.0001)
        let pad = lineWidth * 1.5
        let usableH = size.height - pad * 2
        let stepX = size.width / CGFloat(values.count - 1)
        return values.enumerated().map { index, value in
            let x = CGFloat(index) * stepX
            let y = pad + usableH * (1 - CGFloat((value - minV) / range))
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        path.move(to: pts[0])
        for point in pts.dropFirst() { path.addLine(to: point) }
        return path
    }

    private func areaPath(_ pts: [CGPoint], height: CGFloat) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: pts[0].x, y: height))
        path.addLine(to: pts[0])
        for point in pts.dropFirst() { path.addLine(to: point) }
        path.addLine(to: CGPoint(x: pts[pts.count - 1].x, y: height))
        path.closeSubpath()
        return path
    }
}
