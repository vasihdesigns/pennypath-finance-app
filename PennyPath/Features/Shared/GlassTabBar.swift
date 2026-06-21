//
//  GlassTabBar.swift
//  PennyPath
//
//  Shared floating tab-bar surface for the reskins: real iOS 26 Liquid Glass
//  (`.glassEffect`) when available, with a frosted-material fallback below.
//

import SwiftUI

extension View {
    /// Render the view as a floating Liquid Glass capsule (frosted-material
    /// fallback on iOS 17–25), with a gradient edge-shade rim — a bright lip on
    /// the top edge fading down, plus a soft glow on the bottom edge — for a
    /// beveled, glassy depth.
    @ViewBuilder
    func glassTabBarCapsule() -> some View {
        if #available(iOS 26.0, *) {
            // Real Liquid Glass, tinted so the bar stays a readable surface even
            // when it floats over the light foot of the gradient (dark tint in
            // dark mode, light tint in light mode).
            self.glassEffect(
                .regular.tint(Color.adaptive(light: 0xFFFFFF, dark: 0x121212).opacity(0.55)),
                in: Capsule())
        } else {
            self
                .background(.regularMaterial, in: Capsule())
                .overlay(Capsule().strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5))
        }
    }
}
