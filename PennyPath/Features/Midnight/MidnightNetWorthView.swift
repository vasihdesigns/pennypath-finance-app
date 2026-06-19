//
//  MidnightNetWorthView.swift
//  PennyPath
//
//  Midnight reskin — the blue net-worth screen, adaptive light/dark.
//

import SwiftUI

struct MidnightNetWorthView: View {
    @Environment(\.colorScheme) private var scheme
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var expanded: Set<UUID> = []

    private let tuck: CGFloat = 72
    private let lapVisible: CGFloat = 12

    private let assets: [MidnightAsset] = [
        MidnightAsset(title: "Cash Equivalents", subtitle: "4 accounts",
                      value: "10,250", date: "5 June",
                      fill: Midnight.cardLight, fillBottom: Midnight.cardLightDeep,
                      primary: Color.adaptive(light: 0xEAF1FB, dark: 0x162338),
                      secondary: Color.adaptive(light: 0xAEBCD2, dark: 0x5E6E88),
                      isDark: false,
                      items: [MidnightSubItem(name: "Account 1", value: "2,530"),
                              MidnightSubItem(name: "Account 2", value: "7,720")]),
        MidnightAsset(title: "Investment", subtitle: "Stocks, Mutual funds, Crypto",
                      value: "5,350", date: "10 June",
                      fill: Midnight.cardMid, fillBottom: Midnight.cardMidDeep,
                      primary: Color.adaptive(light: 0xE6EEF8, dark: 0x1A2840),
                      secondary: Color.adaptive(light: 0xA6B4CC, dark: 0x586882),
                      isDark: false,
                      items: [MidnightSubItem(name: "Stocks", value: "2,000"),
                              MidnightSubItem(name: "Mutual funds", value: "1,850"),
                              MidnightSubItem(name: "Crypto", value: "1,500")]),
        MidnightAsset(title: "Property", subtitle: "Lended by Davis",
                      value: "130,000", date: "10 June 2024",
                      fill: Midnight.cardDark, fillBottom: Midnight.cardDarkDeep,
                      primary: Color.adaptive(light: 0x18233A, dark: 0xFFFFFF),
                      secondary: Color.adaptive(light: 0x586882, dark: 0xD2DCEC),
                      isDark: true,
                      items: [MidnightSubItem(name: "Apartment", value: "130,000")]),
        MidnightAsset(title: "Liability", subtitle: "Home Loan, Car Loan",
                      value: "20,520", date: "10 June 2024",
                      fill: Midnight.cardDeepest, fillBottom: Midnight.cardDeepestDeep,
                      primary: Color.adaptive(light: 0x16233B, dark: 0xF0F4FA),
                      secondary: Color.adaptive(light: 0x5E6E88, dark: 0xAEBCD2),
                      isDark: true,
                      items: [MidnightSubItem(name: "Home Loan", value: "15,000"),
                              MidnightSubItem(name: "Car Loan", value: "5,520")])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Net Worth (USD)")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Midnight.onCanvas)
                    Spacer()
                    Button {
                        Haptics.tap()
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Midnight.onCanvas)
                            .frame(width: 42, height: 42)
                            .background((scheme == .dark ? Color.white : Color.black).opacity(0.06), in: Circle())
                            .overlay(Circle().strokeBorder((scheme == .dark ? Color.white : Color.black).opacity(0.16), lineWidth: 1))
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Settings")
                }

                Text("$275,850.20")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Midnight.onCanvas)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 6)

                HStack(spacing: 14) {
                    MidnightGlassPill(label: "Assets")
                    MidnightGlassPill(label: "Liabilities")
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
            MidnightPlusButton { showingAdd = true }
                .padding(.trailing, 22)
                .padding(.bottom, 18)
        }
        .sheet(isPresented: $showingAdd) { AccountFormView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }

    private var stack: some View {
        VStack(spacing: -(tuck - lapVisible)) {
            ForEach(Array(assets.enumerated()), id: \.element.id) { index, asset in
                MidnightAssetCard(asset: asset,
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
