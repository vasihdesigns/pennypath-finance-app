//
//  OnyxNetWorthView.swift
//  PennyPath
//
//  Onyx reskin — the Net Worth screen on the espresso canvas: the big number,
//  glass Assets / Liabilities pills, then each category as a floating warm
//  glass card that expands to reveal its accounts. Settings gear top-right,
//  floating glass +.
//

import SwiftUI

struct OnyxNetWorthView: View {
    @State private var showingAdd = false
    @State private var showingSettings = false
    @State private var expanded: Set<UUID> = []

    private let assets: [OnyxAsset] = [
        OnyxAsset(title: "Cash Equivalents", subtitle: "4 accounts",
                  value: "10,250", date: "5 June",
                  items: [OnyxSubItem(name: "Account 1", value: "2,530"),
                          OnyxSubItem(name: "Account 2", value: "7,720")]),
        OnyxAsset(title: "Investment", subtitle: "Stocks, Mutual funds, Crypto",
                  value: "5,350", date: "10 June",
                  items: [OnyxSubItem(name: "Stocks", value: "2,000"),
                          OnyxSubItem(name: "Mutual funds", value: "1,850"),
                          OnyxSubItem(name: "Crypto", value: "1,500")]),
        OnyxAsset(title: "Property", subtitle: "Lended by Davis",
                  value: "130,000", date: "10 June 2024",
                  items: [OnyxSubItem(name: "Apartment", value: "130,000")]),
        OnyxAsset(title: "Liability", subtitle: "Home Loan, Car Loan",
                  value: "20,520", date: "10 June 2024",
                  items: [OnyxSubItem(name: "Home Loan", value: "15,000"),
                          OnyxSubItem(name: "Car Loan", value: "5,520")])
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .center) {
                    Text("Net Worth (USD)")
                        .font(.system(size: 26, weight: .semibold))
                        .foregroundStyle(Onyx.onCanvas)
                    Spacer()
                    OnyxGlassCircleButton(systemImage: "gearshape.fill",
                                          accessibilityLabel: "Settings") { showingSettings = true }
                }

                Text("$275,850.20")
                    .font(.system(size: 46, weight: .bold))
                    .foregroundStyle(Onyx.onCanvas)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.top, 6)

                HStack(spacing: 14) {
                    OnyxGlassPill(label: "Assets")
                    OnyxGlassPill(label: "Liabilities")
                }
                .padding(.top, 18)

                VStack(spacing: 12) {
                    ForEach(assets) { asset in
                        OnyxAssetCard(asset: asset,
                                      isExpanded: expanded.contains(asset.id)) {
                            Haptics.tap()
                            withAnimation(.snappy) {
                                if expanded.contains(asset.id) { expanded.remove(asset.id) }
                                else { expanded.insert(asset.id) }
                            }
                        }
                    }
                }
                .padding(.top, 18)
            }
            .padding(.horizontal, 22)
            .padding(.top, 10)
            .padding(.bottom, 28)
        }
        .scrollIndicators(.hidden)
        .overlay(alignment: .bottomTrailing) {
            OnyxPlusButton { showingAdd = true }
                .padding(.trailing, 22)
                .padding(.bottom, 18)
        }
        .sheet(isPresented: $showingAdd) { AccountFormView() }
        .sheet(isPresented: $showingSettings) { SettingsView() }
    }
}
