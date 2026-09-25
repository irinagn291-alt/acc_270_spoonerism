import Foundation

/// Role: Work. Bundled Prado shelf. Empty or failed Prado search hangs from here. Not a food catalog.
struct Shelf: Sendable {
    var rows: [CatalogRow]

    static let bundled = Shelf(rows: Self.makeRows())

    private static func makeRows() -> [CatalogRow] {
        [
            row(
                "Q186685",
                "Diego Velazquez",
                "Las Meninas",
                "1656",
                "Las Meninas, by Diego Velazquez, from Prado in Google Earth.jpg"
            ),
            row(
                "Q753175",
                "Francisco Goya",
                "The Third of May 1808",
                "1814",
                "El Tres de Mayo, by Francisco de Goya, from Prado in Google Earth.jpg"
            ),
            row(
                "Q321303",
                "Hieronymus Bosch",
                "The Garden of Earthly Delights",
                "1500",
                "The Garden of Earthly Delights by Bosch High Resolution.jpg"
            ),
            row(
                "Q1242468",
                "Diego Velazquez",
                "The Surrender of Breda",
                "1635",
                "Velazquez-The Surrender of Breda.jpg"
            ),
            row(
                "Q1231009",
                "Francisco Goya",
                "Saturn Devouring His Son",
                "1823",
                "Saturn devouring his son.jpg"
            ),
            row(
                "Q475678",
                "Francisco Goya",
                "The Nude Maja",
                "1800",
                "Goya Maja nuda.jpg"
            ),
            row(
                "Q2277040",
                "El Greco",
                "The Nobleman with his Hand on his Chest",
                "1580",
                "El Greco - Nobleman with his Hand on his Chest.jpg"
            ),
            row(
                "Q1252016",
                "Rogier van der Weyden",
                "The Descent from the Cross",
                "1435",
                "Descent from the Cross van der Weyden.jpg"
            ),
            row(
                "Q1242480",
                "Diego Velazquez",
                "The Spinners",
                "1657",
                "Las Hilanderas by Diego Velazquez.jpg"
            ),
            row(
                "Q2393085",
                "Titian",
                "Equestrian Portrait of Charles V",
                "1548",
                "Titian - Equestrian Portrait of Charles V.jpg"
            ),
        ]
    }

    private static func row(
        _ objectID: String,
        _ artist: String,
        _ title: String,
        _ dated: String,
        _ filename: String
    ) -> CatalogRow {
        CatalogRow(
            objectID: objectID,
            artist: artist,
            title: title,
            imageURLString: CatalogClient.commonsFilePath(filename),
            dated: dated
        )
    }
}
