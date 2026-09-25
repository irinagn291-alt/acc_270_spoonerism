import Foundation

/// Role: Work. Typed lookup failures. Empty or failed Prado lookup stays on the bundled shelf.
enum CatalogFault: Error, Equatable, Sendable {
    case cancelled
    case missing
    case refused
    case transport
    case malformed
}

/// Role: Work. Bundled Museo Nacional del Prado shelf. Leftover cgi search pl is unused. Never a remote catalog.
actor CatalogClient {
    static let userAgent = "Spoonerism/1.0 (iOS; +https://spoonerism-marrow.pro)"
    /// Programmer constant. The domain string is fixed in SPEC.md.
    static let contactURL = URL(string: "https://spoonerism-marrow.pro/contact-us")!
    /// Programmer constant. Museo Nacional del Prado credit lives on Settings.
    static let pradoHomeURL = URL(string: "https://www.museodelprado.es")!
    static let pradoEnglishURL = URL(string: "https://www.museodelprado.es/en")!

    func search(query: String, shelf: [CatalogRow] = Shelf.bundled.rows) -> [CatalogRow] {
        Self.lookup(query: query, shelf: shelf)
    }

    nonisolated static func lookup(query: String, shelf: [CatalogRow] = Shelf.bundled.rows) -> [CatalogRow] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        let needle = trimmed.lowercased()
        return shelf.filter { row in
            row.artist.lowercased().contains(needle) || row.title.lowercased().contains(needle)
        }
    }

    nonisolated static func commonsFilePath(_ filename: String) -> String {
        var allowed = CharacterSet.urlPathAllowed
        allowed.remove(charactersIn: "/")
        let encoded = filename.addingPercentEncoding(withAllowedCharacters: allowed) ?? filename
        return "https://commons.wikimedia.org/wiki/Special:FilePath/\(encoded)"
    }

    nonisolated static func qid(from value: String?) -> String? {
        guard let value else { return nil }
        guard let range = value.range(of: #"Q[0-9]+$"#, options: .regularExpression) else {
            return nil
        }
        return String(value[range])
    }
}
