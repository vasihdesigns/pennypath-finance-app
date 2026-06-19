//
//  AppStoreSearch.swift
//  PennyPath
//
//  Looks up real apps/services by name via Apple's public iTunes Search API, so
//  the subscription form can suggest the right name + icon as you type. The
//  typed text is sent to Apple to perform the search (like the investment price
//  lookups, this is the one place a name leaves the device).
//

import SwiftUI

/// One App Store match: a display name and its icon.
struct AppSuggestion: Identifiable, Hashable {
    let id: String
    let name: String
    let iconURL: URL?
}

enum AppStoreSearch {
    /// Search the App Store for `query`. Returns [] on any failure (offline,
    /// rate-limited, etc.) so the form simply shows no suggestions.
    static func search(_ query: String) async -> [AppSuggestion] {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard q.count >= 2 else { return [] }

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: q),
            URLQueryItem(name: "entity", value: "software"),
            URLQueryItem(name: "limit", value: "12")
        ]
        guard let url = components.url else { return [] }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        guard let (data, response) = try? await URLSession.shared.data(for: request),
              let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode),
              let decoded = try? JSONDecoder().decode(Response.self, from: data) else {
            return []
        }

        var seen = Set<String>()
        return decoded.results.compactMap { item -> AppSuggestion? in
            guard let name = item.trackName, !name.isEmpty, seen.insert(name).inserted else { return nil }
            let iconString = item.artworkUrl100 ?? item.artworkUrl60
            return AppSuggestion(id: item.bundleId ?? name,
                                 name: name,
                                 iconURL: iconString.flatMap { URL(string: $0) })
        }
    }

    private struct Response: Decodable {
        let results: [Item]
        struct Item: Decodable {
            let trackName: String?
            let bundleId: String?
            let artworkUrl60: String?
            let artworkUrl100: String?
        }
    }
}

/// A rounded remote app icon with a neutral placeholder while it loads.
struct AppIconView: View {
    let url: URL?
    var size: CGFloat

    var body: some View {
        AsyncImage(url: url) { image in
            image.resizable().scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: size * 0.23, style: .continuous)
                .fill(Color.secondary.opacity(0.15))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.23, style: .continuous))
    }
}
