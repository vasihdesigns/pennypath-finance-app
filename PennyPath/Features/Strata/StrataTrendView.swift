//
//  StrataTrendView.swift
//  PennyPath
//
//  Strata's Trend sheet: net worth over time from the real snapshot history,
//  with 1M / 6M / 1Y / All range pills — Percento's "Watch your wealth grow"
//  moment. (PennyPath records net worth, so that's the one honest series.)
//

import SwiftUI

struct StrataTrendView: View {
    let snapshots: [NetWorthSnapshot]
    var currencyCode: String = AppSettings.currencyCode

    @Environment(\.dismiss) private var dismiss
    @State private var range: Range = .year

    enum Range: CaseIterable {
        case month, halfYear, year, all
        var title: String {
            switch self {
            case .month: return "1M"
            case .halfYear: return "6M"
            case .year: return "1Y"
            case .all: return "All"
            }
        }
        var days: Int? {
            switch self {
            case .month: return 31
            case .halfYear: return 183
            case .year: return 366
            case .all: return nil
            }
        }
    }

    private var filtered: [NetWorthSnapshot] {
        guard let days = range.days else { return snapshots }
        let cutoff = Date.now.adding(days: -days)
        let inRange = snapshots.filter { $0.date >= cutoff }
        return inRange.count >= 2 ? inRange : snapshots
    }
    private var values: [Double] { filtered.map(\.value) }
    private var current: Double { snapshots.last?.value ?? 0 }
    private var rangeDelta: Double? {
        guard let first = filtered.first?.value, let last = filtered.last?.value,
              filtered.count >= 2 else { return nil }
        return last - first
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            handle
            header

            if values.count >= 2 {
                chart
                StrataPills(items: Range.allCases, title: \.title, selection: $range)
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
            } else {
                emptyNote
            }
            Spacer(minLength: 0)
        }
        .background(Strata.card.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }

    private var handle: some View {
        Capsule().fill(Strata.hairline)
            .frame(width: 38, height: 5)
            .frame(maxWidth: .infinity)
            .padding(.top, 10)
            .padding(.bottom, 6)
    }

    private var header: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                StrataOverline(text: "Net worth", tint: Strata.inkSoft)
                Text(money(current, code: currencyCode))
                    .font(.strataAmount(28, weight: .heavy))
                    .foregroundStyle(Strata.ink)
                if let delta = rangeDelta {
                    let up = delta >= 0
                    Text("\(up ? "+" : "−")\(money(abs(delta), code: currencyCode)) this period")
                        .font(.system(.footnote).weight(.semibold))
                        .foregroundStyle(up ? Strata.cash : Strata.creditCard)
                }
            }
            Spacer()
            Button { dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(Strata.inkSoft)
                    .frame(width: 32, height: 32)
                    .background(Strata.well, in: Circle())
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Close")
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 18)
    }

    private var chart: some View {
        VStack(spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                VStack(alignment: .trailing) {
                    Text(compact(values.max() ?? 0))
                    Spacer()
                    Text(compact(values.min() ?? 0))
                }
                .font(.caption2).foregroundStyle(Strata.inkFaint)
                .frame(width: 44)

                Sparkline(values: values, tint: Strata.investment, lineWidth: 2.5)
                    .frame(height: 150)
            }
            HStack {
                Text(filtered.first?.date.monthYear ?? "")
                Spacer()
                Text(filtered.last?.date.monthYear ?? "")
            }
            .font(.caption2).foregroundStyle(Strata.inkFaint)
            .padding(.leading, 54)
        }
        .padding(.horizontal, 20)
    }

    private var emptyNote: some View {
        Text("Not enough history yet — your trend appears as your net worth is recorded over time.")
            .font(.subheadline)
            .foregroundStyle(Strata.inkSoft)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 30)
            .padding(.vertical, 40)
    }

    /// Short axis label like "1.4M" / "320k".
    private func compact(_ v: Double) -> String {
        let a = abs(v)
        if a >= 1_000_000 { return String(format: "%.1fM", v / 1_000_000) }
        if a >= 1_000 { return String(format: "%.0fk", v / 1_000) }
        return String(format: "%.0f", v)
    }
}
