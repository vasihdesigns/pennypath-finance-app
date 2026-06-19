//
//  SummitOnboardingView.swift
//  PennyPath
//
//  Summit's own one-screen intro. Uses its own first-run flag so it never
//  touches the real app's onboarding state.
//

import SwiftUI

struct SummitOnboardingView: View {
    var onStart: () -> Void

    private let features: [(String, String, String)] = [
        ("chart.line.uptrend.xyaxis", "Track your net worth", "One number that tells the whole story."),
        ("flag.fill", "Reach milestones", "Climb from your first $1K to $1M and beyond."),
        ("sparkles", "Insights, on device", "Quiet guidance from your own numbers.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 12) {
                Text("Summit")
                    .font(.summitSerif(46, weight: .semibold))
                    .foregroundStyle(Summit.ink)
                Text("Build wealth you can see.")
                    .font(.summitText(17))
                    .foregroundStyle(Summit.inkSoft)
            }

            Spacer()

            VStack(spacing: 18) {
                ForEach(features, id: \.0) { feature in
                    HStack(spacing: 14) {
                        Image(systemName: feature.0)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Summit.accent)
                            .frame(width: 44, height: 44)
                            .background(Summit.accentSoft, in: Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(feature.1)
                                .font(.summitText(16, weight: .semibold))
                                .foregroundStyle(Summit.ink)
                            Text(feature.2)
                                .font(.summitText(13))
                                .foregroundStyle(Summit.inkSoft)
                        }
                        Spacer(minLength: 0)
                    }
                }
            }
            .padding(.horizontal, 4)

            Spacer()

            SummitPrimaryButton(title: "Start climbing", systemImage: "arrow.up.right") {
                onStart()
            }
            .padding(.bottom, 8)

            Text("Your numbers never leave this device.")
                .font(.summitText(12))
                .foregroundStyle(Summit.inkFaint)
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Summit.canvas.ignoresSafeArea())
    }
}
