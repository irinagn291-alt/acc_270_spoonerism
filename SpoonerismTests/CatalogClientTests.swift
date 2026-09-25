import XCTest
@testable import Spoonerism

final class CatalogClientTests: XCTestCase {
    func testSearchReadsBundledShelfAndLeavesCgiUnused() async {
        let client = CatalogClient()
        let goya = await client.search(query: "goya")
        XCTAssertFalse(goya.isEmpty)
        XCTAssertTrue(goya.allSatisfy { $0.artist.localizedCaseInsensitiveContains("goya") })
        XCTAssertEqual(
            Set(goya.map(\.objectID)),
            Set(CatalogClient.lookup(query: "goya").map(\.objectID))
        )

        let meninas = await client.search(query: "meninas")
        XCTAssertEqual(meninas.map(\.title), ["Las Meninas"])

        let unknown = await client.search(query: "no-such-painter")
        XCTAssertTrue(unknown.isEmpty)

        let blank = await client.search(query: "   ")
        XCTAssertTrue(blank.isEmpty)

        XCTAssertEqual(CatalogClient.userAgent, "Spoonerism/1.0 (iOS; +https://spoonerism-marrow.pro)")
        XCTAssertEqual(
            CatalogClient.commonsFilePath("Diego Velazquez - Las Meninas.jpg"),
            "https://commons.wikimedia.org/wiki/Special:FilePath/Diego%20Velazquez%20-%20Las%20Meninas.jpg"
        )
        XCTAssertEqual(CatalogClient.qid(from: "http://www.wikidata.org/entity/Q186685"), "Q186685")
        XCTAssertEqual(Shelf.bundled.rows[0].objectID, "Q186685")
        XCTAssertEqual(Shelf.bundled.rows[0].title, "Las Meninas")
        XCTAssertFalse(CatalogClient.userAgent.contains("cgi/search.pl"))
        XCTAssertFalse(CatalogClient.contactURL.absoluteString.contains("cgi/search.pl"))
    }
}
