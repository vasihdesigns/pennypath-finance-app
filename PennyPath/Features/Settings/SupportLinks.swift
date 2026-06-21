//
//  SupportLinks.swift
//  PennyPath
//
//  The external links shown in Settings (privacy policy, support, terms).
//
//  ⚠️ BEFORE APP STORE SUBMISSION: replace the placeholder URLs and email below
//  with your real ones. App Store Guideline 5.1.1 requires a working privacy
//  policy link both here and in App Store Connect, and App Store Connect
//  requires a valid Support URL. The app reads these in one place so there's
//  only one spot to update. See RELEASE.md.
//

import Foundation
#if canImport(UIKit)
import UIKit
#endif

enum SupportLinks {
    /// Required by the App Store. Host a simple page (e.g. GitHub Pages) stating
    /// that all data stays on the device and nothing is collected.
    static let privacyPolicy = URL(string: "https://vasihdesigns.github.io/pennypath/privacy")!

    /// Optional but recommended. A short terms-of-use / EULA page.
    static let terms = URL(string: "https://vasihdesigns.github.io/pennypath/terms")!

    /// Where "Contact Support" sends mail. Use an address you actually monitor.
    static let supportEmail = "support@pennypath.app"

    /// The App Store product page, used by "Rate PennyPath". Fill in the numeric
    /// id once the app exists in App Store Connect (Apple ID under App Information).
    /// Until then the in-app review prompt still works without it.
    static let appStoreID = "0000000000"

    /// A pre-addressed mail link with a helpful subject and a diagnostic footer
    /// so support requests arrive with the app/OS version already filled in.
    static func supportMailURL(appVersion: String, build: String) -> URL? {
        let subject = "PennyPath support"
        let body = "\n\n\n—\nPennyPath \(appVersion) (\(build)) · iOS \(systemVersion)"
        var components = URLComponents()
        components.scheme = "mailto"
        components.path = supportEmail
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    /// A direct "write a review" deep link to the App Store review tab.
    static var writeReviewURL: URL? {
        URL(string: "https://apps.apple.com/app/id\(appStoreID)?action=write-review")
    }

    private static var systemVersion: String {
        #if canImport(UIKit)
        return UIDevice.current.systemVersion
        #else
        return ProcessInfo.processInfo.operatingSystemVersionString
        #endif
    }
}
