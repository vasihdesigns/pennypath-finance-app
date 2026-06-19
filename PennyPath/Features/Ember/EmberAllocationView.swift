//
//  EmberAllocationView.swift
//  PennyPath
//
//  The net-worth allocation page, opened full-screen from the pie-chart icon on
//  the Net Worth header. Deliberately spare: the net-worth total at the top, a
//  close button, and the asset categories laid out as a squarified treemap —
//  proportional boxes packed into a grid, each labelled with its share of total
//  assets. No tab bar, no scrolling. Bronze ramp, deepest box for the biggest
//  share.
//

import SwiftUI

/// One box in the allocation grid: a money kind, its value, and its share of
/// total assets.
struct EmberAllocationSlice: Identifiable {
    let kind: EmberMoneyKind
    let value: Double
    let pct: Double
    var id: String { kind.id }
}

struct EmberAllocationView: View {
    @Environment(\.colorScheme) private var scheme
    /// Asset slices, sorted by value descending, each with value > 0.
    let slices: [EmberAllocationSlice]
    let netWorth: Double
    let currencyCode: String
    var onClose: () -> Void

    private let gap: CGFloat = 5

    var body: some View {
        VStack(spacing: 16) {
            topBar
            GeometryReader { geo in
                grid(in: geo.size)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 18)
        .padding(.bottom, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Ember.canvas.ignoresSafeArea())
    }

    // MARK: Top bar — net worth + close

    private var topBar: some View {
        HStack(alignment: .top, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Net Worth")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Ember.onCanvasSoft)
                Text(money(netWorth, code: currencyCode))
                    .font(.system(size: 30, weight: .bold))
                    .foregroundStyle(Ember.onCanvas)
                    .lineLimit(1).minimumScaleFactor(0.5)
            }
            Spacer(minLength: 8)
            Button {
                Haptics.tap()
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Ember.onCanvas)
                    .frame(width: 42, height: 42)
                    .background(Ember.glassFill(dark: scheme == .dark), in: Circle())
                    .overlay(Circle().strokeBorder(Ember.glassStroke(dark: scheme == .dark), lineWidth: 1))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
    }

    // MARK: Treemap grid

    private func grid(in size: CGSize) -> some View {
        let rects = Self.squarified(values: slices.map { CGFloat($0.value) },
                                    in: CGRect(origin: .zero, size: size))
        return ZStack(alignment: .topLeading) {
            ForEach(Array(slices.enumerated()), id: \.element.id) { index, slice in
                let r = rects[index]
                tile(slice, size: r.size)
                    .frame(width: max(r.width - gap, 1), height: max(r.height - gap, 1))
                    .offset(x: r.minX + gap / 2, y: r.minY + gap / 2)
            }
        }
    }

    /// Each box wears its category's deck-card colours, so the allocation grid
    /// reads as the same deck — Investment bronze, Liability espresso, etc.
    private func tile(_ slice: EmberAllocationSlice, size: CGSize) -> some View {
        let kind = slice.kind
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        let minSide = min(size.width, size.height)
        let pctSize = min(max(minSide * 0.24, 15), 48)
        let nameSize: CGFloat = minSide < 92 ? 12 : 15
        return VStack(alignment: .leading, spacing: 2) {
            Text(Self.pctText(slice.pct))
                .font(.system(size: pctSize, weight: .bold))
                .foregroundStyle(kind.primary)
                .lineLimit(1).minimumScaleFactor(0.4)
            Spacer(minLength: 0)
            Text(kind.title)
                .font(.system(size: nameSize, weight: .medium))
                .foregroundStyle(kind.secondary)
                .lineLimit(2).minimumScaleFactor(0.6)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
        .background {
            shape.fill(LinearGradient(colors: [kind.fill, kind.fillBottom],
                                      startPoint: .topLeading, endPoint: .bottomTrailing))
                .overlay(shape.fill(LinearGradient(
                    colors: [.white.opacity(0.16), .white.opacity(0.03), .clear],
                    startPoint: .topLeading, endPoint: .bottomTrailing)))
        }
        .overlay(
            shape.strokeBorder(LinearGradient(
                colors: [.white.opacity(0.40), .white.opacity(0.10)],
                startPoint: .top, endPoint: .bottom), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(kind.title), \(Self.pctText(slice.pct)), \(money(slice.value, code: currencyCode))")
    }

    // MARK: Helpers

    static func pctText(_ p: Double) -> String {
        if p >= 0.95 { return "\(Int(p.rounded()))%" }
        return String(format: "%.1f%%", p)
    }

    /// Squarified treemap: tiles whose areas are proportional to `values`
    /// (expected sorted descending), packed to fill `bounds` with reasonable
    /// aspect ratios — large shares as bands, small ones grouped into a grid.
    static func squarified(values: [CGFloat], in bounds: CGRect) -> [CGRect] {
        var result = [CGRect](repeating: .zero, count: values.count)
        let total = values.reduce(0, +)
        guard total > 0, bounds.width > 0, bounds.height > 0 else { return result }
        let scale = (bounds.width * bounds.height) / total
        let areas = values.map { $0 * scale }

        func worst(_ row: [CGFloat], _ side: CGFloat) -> CGFloat {
            guard let mx = row.max(), let mn = row.min(), mn > 0, side > 0 else { return .infinity }
            let s = row.reduce(0, +)
            let side2 = side * side
            let s2 = s * s
            return max(side2 * mx / s2, s2 / (side2 * mn))
        }

        var rect = bounds
        var i = 0
        while i < areas.count {
            var row: [CGFloat] = [areas[i]]
            var rowIdx: [Int] = [i]
            var next = i + 1
            while next < areas.count {
                let side = min(rect.width, rect.height)
                if worst(row + [areas[next]], side) <= worst(row, side) {
                    row.append(areas[next]); rowIdx.append(next); next += 1
                } else { break }
            }
            let rowSum = row.reduce(0, +)
            if rect.width >= rect.height {
                let colW = rowSum / rect.height
                var y = rect.minY
                for (k, idx) in rowIdx.enumerated() {
                    let h = row[k] / colW
                    result[idx] = CGRect(x: rect.minX, y: y, width: colW, height: h)
                    y += h
                }
                rect = CGRect(x: rect.minX + colW, y: rect.minY,
                              width: rect.width - colW, height: rect.height)
            } else {
                let rowH = rowSum / rect.width
                var x = rect.minX
                for (k, idx) in rowIdx.enumerated() {
                    let w = row[k] / rowH
                    result[idx] = CGRect(x: x, y: rect.minY, width: w, height: rowH)
                    x += w
                }
                rect = CGRect(x: rect.minX, y: rect.minY + rowH,
                              width: rect.width, height: rect.height - rowH)
            }
            i = next
        }
        return result
    }
}
