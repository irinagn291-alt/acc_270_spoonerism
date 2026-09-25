import XCTest
@testable import Spoonerism

final class OnsetFoldTests: XCTestCase {
    private var calendar: Calendar { SpoonerismGMT.calendar }
    private var now: Date { SpoonerismGMT.instant(2026, 9, 19) }
    private var titlePicker: FixedFieldPicker { FixedFieldPicker(field: .title) }
    private var artistPicker: FixedFieldPicker { FixedFieldPicker(field: .artist) }
    private var pairing: FirstLastPairing { FirstLastPairing() }
    private var shelf: [CatalogRow] { Shelf.bundled.rows }

    func test_architecture_sampling_refuse_missKeep_oneMendFolds_fluent_duplicateFocus() throws {
        var idle = Onset.empty
        XCTAssertThrowsError(try idle.mend(UUID(), now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? OnsetFault, .mendOnIdle)
        }
        try idle.spoonWork(picker: titlePicker, pairing: pairing)
        XCTAssertEqual(foldLabel(idle.hanging), "fluent")
        XCTAssertEqual(idle.sign, .fluent)

        var onset = try stockedAndSpooned(picker: titlePicker)
        XCTAssertEqual(onset.sign, .spooned)
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        let line = try XCTUnwrap(onset.line)
        XCTAssertEqual(line.field, .title)
        XCTAssertEqual(line.heads.map(\.seat), Array(0 ..< line.heads.count))
        let left = try XCTUnwrap(line.head(id: line.leftID))
        let right = try XCTUnwrap(line.head(id: line.rightID))
        XCTAssertEqual(left.wornOpening, right.nativeOpening)
        XCTAssertEqual(right.wornOpening, left.nativeOpening)
        XCTAssertNotEqual(left.spoken, left.prefix + left.nativeOpening + left.stem)

        XCTAssertThrowsError(try onset.spoonWork(picker: titlePicker, pairing: pairing)) { error in
            XCTAssertEqual(error as? OnsetFault, .alreadySpooned)
        }
        let hangingID = try XCTUnwrap(onset.hangingWork?.id)

        let miss = try XCTUnwrap(onset.line?.heads.first { !line.isSwapped($0.id) })
        _ = try onset.mend(miss.id, now: now, calendar: calendar)
        XCTAssertEqual(onset.hangingWork?.id, hangingID)
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        XCTAssertEqual(onset.sign, .spooned)
        XCTAssertEqual(onset.line?.head(id: miss.id)?.isGrey, true)
        XCTAssertEqual(onset.reviewableMuffs.count, 1)
        XCTAssertEqual(onset.mendedWorks.count, 0)

        try mendOnce(&onset)
        XCTAssertEqual(foldLabel(onset.hanging), "mended")
        XCTAssertEqual(onset.hangingWork?.fold, .mended)
        XCTAssertFalse(onset.spoonPool.contains { $0.id == hangingID })
        XCTAssertEqual(onset.sign, .mended)
        XCTAssertEqual(onset.reviewableMends.count, 1)
        let restoredLeft = try XCTUnwrap(onset.line?.head(id: line.leftID))
        let restoredRight = try XCTUnwrap(onset.line?.head(id: line.rightID))
        XCTAssertEqual(restoredLeft.wornOpening, restoredLeft.nativeOpening)
        XCTAssertEqual(restoredRight.wornOpening, restoredRight.nativeOpening)
        XCTAssertTrue(restoredLeft.isRighted)
        XCTAssertTrue(restoredRight.isRighted)

        try onset.undoNewest()
        XCTAssertEqual(foldLabel(onset.hanging), "spooned")
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        XCTAssertEqual(onset.mendedWorks.count, 0)
        XCTAssertTrue(onset.spoonPool.contains { $0.id == hangingID })
        XCTAssertTrue(onset.canMend)
    }

    func test_primaryVerb_emptyPopulatedInvalid() throws {
        var empty = Onset.empty
        try empty.spoonWork(picker: titlePicker, pairing: pairing)
        XCTAssertEqual(empty.sign, .fluent)
        XCTAssertFalse(empty.canMend)
        XCTAssertThrowsError(try empty.mend(UUID(), now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? OnsetFault, .mendOnIdle)
        }

        var onset = try stockedAndSpooned(picker: titlePicker)
        XCTAssertTrue(onset.canMend)
        XCTAssertEqual(onset.sign, .spooned)
        XCTAssertFalse(onset.line?.heads.isEmpty ?? true)

        XCTAssertThrowsError(try onset.mend(UUID(), now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? OnsetFault, .unknownHead)
        }
        let miss = try XCTUnwrap(onset.line?.heads.first { head in
            !(onset.line?.isSwapped(head.id) ?? true)
        })
        _ = try onset.mend(miss.id, now: now, calendar: calendar)
        XCTAssertThrowsError(try onset.mend(miss.id, now: now, calendar: calendar)) { error in
            XCTAssertEqual(error as? OnsetFault, .alreadyGrey)
        }
        XCTAssertThrowsError(try empty.undoNewest()) { error in
            XCTAssertEqual(error as? OnsetFault, .nothingToPeel)
        }
    }

    func test_twist_spoonThenMend_xorField_duplicateObjectIDFocuses_thinFieldRefused() throws {
        var titleOnset = try stockedAndSpooned(picker: titlePicker)
        XCTAssertEqual(titleOnset.line?.field, .title)
        XCTAssertEqual(
            titleOnset.line?.heads.map(\.spoken).joined(separator: " ").contains(" "),
            true
        )

        let artistOnset = try stockedAndSpooned(picker: artistPicker, row: shelf[1])
        XCTAssertEqual(artistOnset.line?.field, .artist)
        XCTAssertEqual(artistOnset.hangingWork?.artist, shelf[1].artist)

        try mendOnce(&titleOnset)
        XCTAssertEqual(titleOnset.hangingWork?.fold, .mended)

        let again = try titleOnset.keepWork(shelf[1], now: now, calendar: calendar)
        guard case .focused(let id) = again else {
            return XCTFail("expected focus")
        }
        XCTAssertEqual(id, titleOnset.works[0].id)
        XCTAssertEqual(titleOnset.works.count, 1)
        XCTAssertEqual(titleOnset.works[0].fold, .mended)
        XCTAssertEqual(titleOnset.focusedWorkID, id)
        XCTAssertEqual(foldLabel(titleOnset.hanging), "mended")

        _ = try titleOnset.keepWork(shelf[0], now: now, calendar: calendar)
        XCTAssertEqual(titleOnset.works.count, 2)
        try titleOnset.spoonWork(picker: titlePicker, pairing: pairing)
        XCTAssertNotEqual(titleOnset.hangingWork?.fold, .mended)
        XCTAssertEqual(titleOnset.hangingWork?.fold, .spooned)
        XCTAssertNotEqual(titleOnset.hangingWork?.objectID, shelf[1].objectID)

        XCTAssertThrowsError(
            try LinePress.make(
                work: Work.idle(
                    from: CatalogRow(
                        objectID: "Q0THIN",
                        artist: "Goya",
                        title: "Maja",
                        imageURLString: "https://commons.wikimedia.org/wiki/Special:FilePath/Maja.jpg",
                        dated: "1800"
                    ),
                    daykey: 20260919
                ),
                field: .title,
                pairing: pairing
            )
        ) { error in
            XCTAssertEqual(error as? OnsetFault, .thinField)
        }

        var thin = Onset.empty
        _ = try thin.keepWork(
            CatalogRow(
                objectID: "Q0THIN",
                artist: "Goya",
                title: "Maja",
                imageURLString: "https://commons.wikimedia.org/wiki/Special:FilePath/Maja.jpg",
                dated: "1800"
            ),
            now: now,
            calendar: calendar
        )
        try thin.spoonWork(picker: titlePicker, pairing: pairing)
        XCTAssertEqual(thin.sign, .fluent)
        XCTAssertFalse(thin.canMend)
    }

    func test_seedPaintsLiveLineAndEnablesMend() {
        let onset = OnsetSeed.onset(now: now, calendar: calendar, picker: titlePicker, pairing: pairing, shelf: shelf)
        XCTAssertTrue(onset.onboardingComplete)
        XCTAssertTrue(onset.canMend)
        XCTAssertEqual(onset.hangingWork?.fold, .spooned)
        XCTAssertEqual(foldLabel(onset.hanging), "spooned")
        XCTAssertGreaterThanOrEqual(onset.works.count, 6)
        XCTAssertGreaterThanOrEqual(onset.mendedWorks.count, 2)
        XCTAssertGreaterThanOrEqual(onset.reviewableMuffs.count, 3)
        XCTAssertGreaterThanOrEqual(onset.spoonPool.count, 3)
        XCTAssertNotEqual(onset.sign, .fluent)
        XCTAssertEqual(onset.line?.openSwapped.count, 2)
        XCTAssertFalse(onset.line?.heads.isEmpty ?? true)
    }

    func test_daykeyIsYYYYMMDDFromStartOfDay() {
        let late = SpoonerismGMT.instant(2026, 9, 19, hour: 23)
        let next = SpoonerismGMT.instant(2026, 9, 20, hour: 1)
        XCTAssertEqual(Daykey.stamp(late, calendar: calendar), 20260919)
        XCTAssertEqual(Daykey.stamp(next, calendar: calendar), 20260920)
        XCTAssertEqual(Daykey.shifting(20260919, by: -1, calendar: calendar), 20260918)
    }

    func test_samplesOnlyNotMendedWorks() throws {
        var onset = try stockedAndSpooned(picker: titlePicker)
        let firstID = try XCTUnwrap(onset.hangingWork?.id)
        try mendOnce(&onset)
        _ = try onset.keepWork(shelf[0], now: now, calendar: calendar)
        try onset.spoonWork(picker: titlePicker, pairing: pairing)
        XCTAssertNotEqual(onset.hangingWork?.id, firstID)
        XCTAssertNotEqual(onset.hangingWork?.fold, .mended)
        XCTAssertFalse(onset.mendedWorks.contains { $0.id == onset.hangingWork?.id })
    }

    func test_muffThenUndoRestoresTheWord() throws {
        var onset = try stockedAndSpooned(picker: titlePicker)
        let miss = try XCTUnwrap(onset.line?.heads.first { head in
            !(onset.line?.isSwapped(head.id) ?? true)
        })
        _ = try onset.mend(miss.id, now: now, calendar: calendar)
        XCTAssertEqual(onset.reviewableMuffs.count, 1)
        try onset.undoNewest()
        XCTAssertEqual(onset.reviewableMuffs.count, 0)
        XCTAssertEqual(onset.line?.head(id: miss.id)?.isGrey, false)
        XCTAssertEqual(onset.sign, .spooned)
    }

    func test_openingsAreFirstLettersAndSeatsStay() {
        XCTAssertTrue(HeadCut.qualifies("Las Meninas"))
        XCTAssertTrue(HeadCut.qualifies("Red Fox"))
        XCTAssertFalse(HeadCut.qualifies("Olympia"))
        XCTAssertFalse(HeadCut.qualifies("Maja"))
        let pieces = HeadCut.pieces(in: "The Nude Maja")
        XCTAssertEqual(pieces.map(\.opening), ["T", "N", "M"])
        XCTAssertEqual(HeadCut.distinctSeats(in: pieces).count, 3)
    }

    private func stockedAndSpooned(
        picker: FixedFieldPicker,
        row: CatalogRow? = nil
    ) throws -> Onset {
        var onset = Onset.empty
        _ = try onset.keepWork(row ?? shelf[1], now: now, calendar: calendar)
        try onset.spoonWork(picker: picker, pairing: pairing)
        return onset
    }

    private func mendOnce(_ onset: inout Onset) throws {
        let head = try XCTUnwrap(onset.line?.openSwapped.first)
        _ = try onset.mend(head.id, now: now, calendar: calendar)
    }

    private func foldLabel(_ hang: OnsetHang) -> String {
        switch hang {
        case .fluent:
            return "fluent"
        case .idle:
            return "idle"
        case .spooned:
            return "spooned"
        case .mended:
            return "mended"
        }
    }
}
