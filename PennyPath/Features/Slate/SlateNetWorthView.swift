//
//  SlateNetWorthView.swift
//  PennyPath
//
//  Slate reskin — the Ember net-worth screen in charcoal, adaptive light/dark.
//

import SwiftUI

struct SlateNetWorthView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var expanded: Set<UUID> = []

    private let tuck: CGFloat = 72
    private let lapVisible: CGFloat = 12

    private let assets: [SlateAsset] = [
        SlateAsset(title: "Cash Equivalents", subtitle: "4 accounts",
                   value: "10,250", date: "5 June",
                   fill: Slate.cardLight, fillBottom: Slate.cardLightDeep,
                   primary: Color.adaptive(light: 0xF4F4F6, dark: 0x1C1C20),
                   secondary: Color.adaptive(light: 0xB6B6BE, dark: 0x6E6E78),
                   isDark: false,
                   items: [SlateSubItem(name: "Account 1", value: "2,530"),
                           SlateSubItem(name: "Account 2", value: "7,720")]),
        SlateAsset(title: "Investment", subtitle: "Stocks, Mutual funds, Crypto",
                   value: "5,350", date: "10 June",
                   fill: Slate.cardMid, fillBottom: Slate.cardMidDeep,
                   primary: Color.adaptive(light: 0xF0F0F2, dark: 0x222227),
                   secondary: Color.adaptive(light: 0xB0B0B8, dark: 0x66666E),
                   isDark: false,
                   items: [SlateSubItem(name: "Stocks", value: "2,000"),
                           SlateSubItem(name: "Mutual funds", value: "1,850"),
                           SlateSubItem(name: "Crypto", value: "1,500")]),
        SlateAsset(title: "Property", subtitle: "Lended by Davis",
                   value: "130,000", date: "10 June 2024",
                   fill: Slate.cardDark, fillBottom: Slate.cardDarkDeep,
                   primary: Color.adaptive(light: 0x26262B, dark: 0xFFFFFF),
                   secondary: Color.adaptive(light: 0x66666E, dark: 0xDADADE),
                   isDark: true,
                   items: [SlateSubItem(name: "Apartment", value: "130,000")]),
        SlateAsset(title: "Liability", subtitle: "Home Loan, Car Loan",
                   value: "20,520", date: "10 June 2024",
                   fill: Slate.cardDeepest, fillBottom: Slate.cardDeepestDeep,
                   primary: Color.adaptive(light: 0x1C1C20, dark: 0xF4F4F6),
                   secondary: Color.adaptive(light: 0x6E6E78, dark: 0xB6B6BE),
                   isDark: true,
                   items: [SlateSubItem(name: "Home Loan", value: "15,000"),
                           SlateSubItem(name: "Car Loan", value: "5,520")])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Net Worth (USD)")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Slate.onCanvas)
                    Spacer()
                    Button {
                        Haptics.tap()
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Slate.onCanvas)
                            .frame(width: 42, height: 42)
                            .background((scheme == .dark ? Color.white : Color.black).opacity(0.06), in: Circle())
                            .overlay(Circle().strokeBorder((scheme == .dark ? Color.white : Color.black).opacity(0.16), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }

                Text("$275,850.20")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Slate.onCanvas)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 6)

                HStack(spacing: 14) {
                    SlateGlassPill(label: "Assets")
                    SlateGlassPill(label: "Liabilities")
                }
                .padding(.top, 18)

                stack
                    .padding(.top, 22)
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottomTrailing) {
            SlatePlusButton { showingAdd = true }
                .padding(.trailing, 22)
                .padding(.bottom, 18)
        }
        .sheet(isPresented: $showingAdd) { AccountFormView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    private var stack: some View {
        VStack(spacing: -(tuck - lapVisible)) {
            ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                SlateAssetCard(asset: asset,
                               isExpanded: expanded.contains(asset.id),
                               isLast: index == assets.count - 1,
                               tuck: tuck) {
                    Haptics.tap()
                    withAnimation(.snappy) {
                        if expanded.contains(asset.id) { expanded.remove(asset.id) }
                        else { expanded.insert(asset.id) }
                    }
                }
                .zIndex(Double(index))
            }
        }
    }
}
