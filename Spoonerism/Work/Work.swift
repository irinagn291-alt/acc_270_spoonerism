import Foundation

/// Role: Work. Saved Prado accession with maker, title, Commons image, daykey Int YYYYMMDD, and stored fold case.
struct Work: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var objectID: String
    var artist: String
    var title: String
    var imageURLString: String?
    var dated: String?
    var daykey: Int
    var fold: WorkFold

    var imageURL: URL? {
        guard let imageURLString, !imageURLString.isEmpty else { return nil }
        return URL(string: imageURLString)
    }

    static func idle(
        from row: CatalogRow,
        id: UUID = UUID(),
        daykey: Int
    ) -> Work {
        Work(
            id: id,
            objectID: row.objectID,
            artist: row.artist,
            title: row.title,
            imageURLString: row.imageURLString,
            dated: row.dated,
            daykey: daykey,
            fold: .idle
        )
    }
}

/// Role: Work. Closed algebraic fold Idle, Spooned, or Mended. A fourth case is a defect. Stored on Work; mended-ness is not a parallel bool.
enum WorkFold: String, Equatable, Sendable, Codable {
    case idle
    case spooned
    case mended

    var isMended: Bool { self == .mended }
}

/// Role: Work. Catalog row before it is written Idle. Cached so empty or failed Prado lookup still spoons from the shelf.
struct CatalogRow: Identifiable, Equatable, Sendable, Codable {
    var objectID: String
    var artist: String
    var title: String
    var imageURLString: String?
    var dated: String?

    var id: String { objectID }

    var imageURL: URL? {
        guard let imageURLString, !imageURLString.isEmpty else { return nil }
        return URL(string: imageURLString)
    }
}
