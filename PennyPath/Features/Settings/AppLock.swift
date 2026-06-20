//
//  AppLock.swift
//  PennyPath
//
//  Optional Face ID / Touch ID lock. When enabled, the app's contents are
//  covered the moment it leaves the foreground and stay hidden behind a lock
//  screen until the device owner authenticates — so balances aren't exposed in
//  the app switcher or to anyone who picks up an unlocked phone.
//
//  Requires the `NSFaceIDUsageDescription` Info.plist string (set in build
//  settings) so iOS can show the Face ID prompt.
//

import SwiftUI
import LocalAuthentication
import OSLog

@Observable
final class AppLockManager {
    static let shared = AppLockManager()

    static let enabledKey = "appLockEnabled"
    private static let logger = Logger(subsystem: "com.vasih.PennyPath", category: "AppLock")

    /// True while the lock screen is covering the app's contents.
    private(set) var isLocked: Bool
    /// True once an unlock attempt is in flight, so the UI can avoid double-prompting.
    private(set) var isAuthenticating = false

    /// Whether the user has turned the lock on. Reading/writing goes straight to
    /// `UserDefaults` so it stays in sync with the `@AppStorage` toggle in Settings.
    var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: Self.enabledKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: Self.enabledKey)
            // Turning it off here-and-now should immediately reveal the app.
            if !newValue { isLocked = false }
        }
    }

    private init() {
        // Start locked if the feature is on, so a cold launch must authenticate.
        isLocked = UserDefaults.standard.bool(forKey: Self.enabledKey)
    }

    /// Whether the device can actually do biometric / passcode auth right now.
    var biometryType: LABiometryType {
        let context = LAContext()
        _ = context.canEvaluatePolicy(.deviceOwnerAuthentication, error: nil)
        return context.biometryType
    }

    /// Cover the app when it goes to the background (called on scene-phase change).
    func lockForBackground() {
        guard isEnabled else { return }
        isLocked = true
    }

    /// Prompt for Face ID / Touch ID (falling back to the device passcode). On
    /// success the lock screen is removed. Safe to call repeatedly.
    @MainActor
    func authenticate() async {
        guard isLocked, !isAuthenticating else { return }
        isAuthenticating = true
        defer { isAuthenticating = false }

        let context = LAContext()
        context.localizedFallbackTitle = "Enter Passcode"
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) else {
            // No biometrics and no passcode set — don't trap the user out of
            // their own data; reveal the app rather than locking forever.
            Self.logger.error("Cannot evaluate auth policy: \(error?.localizedDescription ?? "unknown", privacy: .public)")
            isLocked = false
            return
        }

        do {
            let ok = try await context.evaluatePolicy(.deviceOwnerAuthentication,
                                                      localizedReason: "Unlock PennyPath to see your money.")
            if ok { isLocked = false }
        } catch {
            // Cancelled or failed — stay locked; the lock screen offers a retry.
            Self.logger.notice("Auth not completed: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// The full-screen cover shown while the app is locked. Hides all content and
/// offers a single button to authenticate.
struct AppLockView: View {
    @State private var lock = AppLockManager.shared

    var body: some View {
        ZStack {
            Theme.background.ignoresSafeArea()
            VStack(spacing: Theme.Space.lg) {
                Image(systemName: lock.biometryType == .touchID ? "touchid" : "faceid")
                    .font(.system(size: 56, weight: .regular))
                    .foregroundStyle(Theme.ink)
                    .accessibilityHidden(true)
                Text("PennyPath is locked")
                    .font(.display(22))
                    .foregroundStyle(Theme.ink)
                Text("Your money is hidden until you unlock.")
                    .font(.subheadline)
                    .foregroundStyle(Theme.inkSecondary)
                    .multilineTextAlignment(.center)
                Button("Unlock") {
                    Task { await lock.authenticate() }
                }
                .buttonStyle(PrimaryButtonStyle(tint: Theme.ink))
                .padding(.top, Theme.Space.sm)
            }
            .padding(Theme.Space.xl)
        }
        // Prompt as soon as the lock screen appears (e.g. on launch / re-entry).
        .task { await lock.authenticate() }
    }
}
