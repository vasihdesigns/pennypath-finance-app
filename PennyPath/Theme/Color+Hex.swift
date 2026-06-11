//
//  Color+Hex.swift
//  PennyPath
//
//  Small helpers for building colors from hex and for light/dark adaptive colors.
//

import SwiftUI
import UIKit

extension Color {
    /// Build a color from a 0xRRGGBB hex value.
    init(hex: UInt) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }

    /// A color that automatically swaps between a light-mode and dark-mode value.
    static func adaptive(light: UInt, dark: UInt) -> Color {
        Color(uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(Color(hex: dark))
                : UIColor(Color(hex: light))
        })
    }
}
