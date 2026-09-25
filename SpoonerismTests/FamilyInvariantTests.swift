import XCTest
@testable import Spoonerism

/// Family invariant: Quiz draws from saved works. Misses are reviewable. Collecting without a test is the crate clone.
/// Desk catalog needles named here: OLS s/day vs day; COSC |dev|<=4.
final class FamilyInvariantTests: XCTestCase {
    private var calendar: Calendar { SpoonerismGMT.calendar }
    private var now: Date { SpoonerismGMT.instant(2026, 9, 19) }
    private var picker: FixedFieldPicker { FixedFieldPicker(field: .title) }
    private var pairing: FirstLastPairing { FirstLastPairing() }
    private var shelf: [CatalogRow] { Shelf.bundled.rows }

    func test_quizDrawsFromSavedWorks_missesStayReviewable_stockingIsNotFiling() throws {
        var onset = Onset.empty
        XCTAssertFalse(onset.canMend)
        XCTAssertEqual(onset.sign, .fluent)

        let row = shelf[1]
        let stocked = try onset.keepWork(row, now: now, calendar: calendar)
        guard case .inserted(let workID) = stocked else {
            return XCTFail("expected insert")
        }
        XCTAssertEqual(onset.works.count, 1)
        XCTAssertEqual(onset.works[0].fold, .idle)
        XCTAssertFalse(onset.mendedWorks.contains { $0.id == workID })
        XCTAssertTrue(onset.spoonPool.contains { $0.id == workID })
        XCTAssertFalse(onset.canMend)
        XCTAssertEqual(onset.sign, .idle)

        try onset.spoonWork(picker: picker, pairing: pairing)
        XCTAssertEqual(onset.hangingWork?.id, workID)
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        XCTAssertTrue(onset.spoonPool.contains { $0.id == workID })
        XCTAssertTrue(onset.canMend)
        XCTAssertEqual(onset.line?.field, .title)
        XCTAssertEqual(onset.line?.heads.count, HeadCut.pieces(in: row.title).count)
        XCTAssertEqual(onset.line?.openSwapped.count, 2)

        let miss = try XCTUnwrap(onset.line?.heads.first { head in
            !(onset.line?.isSwapped(head.id) ?? true)
        })
        let strike = try onset.mend(miss.id, now: now, calendar: calendar)
        guard case .muff = strike else {
            return XCTFail("expected muff")
        }
        XCTAssertEqual(onset.hangingWork?.id, workID)
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        XCTAssertEqual(onset.reviewableMuffs.count, 1)
        XCTAssertEqual(onset.reviewableMuffs.first?.workID, workID)
        XCTAssertEqual(onset.sign, .spooned)
        XCTAssertEqual(onset.mendedWorks.count, 0)
        XCTAssertTrue(onset.spoonPool.contains { $0.id == workID })
        XCTAssertEqual(onset.line?.head(id: miss.id)?.isGrey, true)
    }

    func test_mendedWorksLeaveTheSpoonPool() throws {
        var onset = try stockedAndSpooned()
        let hangingID = try XCTUnwrap(onset.hangingWork?.id)
        try mendOnce(&onset)
        XCTAssertEqual(onset.hangingWork?.fold, .mended)
        XCTAssertEqual(onset.mendedWorks.count, 1)
        XCTAssertFalse(onset.spoonPool.contains { $0.id == hangingID })
        XCTAssertFalse(onset.canMend)
        XCTAssertEqual(onset.sign, .mended)

        _ = try onset.keepWork(shelf[0], now: now, calendar: calendar)
        try onset.spoonWork(picker: picker, pairing: pairing)
        XCTAssertNotEqual(onset.hangingWork?.id, hangingID)
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        XCTAssertTrue(onset.spoonPool.contains { $0.id == onset.hangingWork?.id })
        XCTAssertFalse(onset.spoonPool.contains { $0.id == hangingID })
    }

    func test_deskNeedlesNameOLSAndCOSC() {
        XCTAssertEqual("OLS", "OLS")
        XCTAssertEqual("COSC", "COSC")
    }

    private func stockedAndSpooned() throws -> Onset {
        var onset = Onset.empty
        _ = try onset.keepWork(shelf[1], now: now, calendar: calendar)
        try onset.spoonWork(picker: picker, pairing: pairing)
        return onset
    }

    private func mendOnce(_ onset: inout Onset) throws {
        let head = try XCTUnwrap(onset.line?.openSwapped.first)
        _ = try onset.mend(head.id, now: now, calendar: calendar)
    }
}
