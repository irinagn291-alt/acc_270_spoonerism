import XCTest
@testable import Spoonerism

final class SpoonerismTests: XCTestCase {
    func test_appModuleImports() {
        XCTAssertEqual(String(describing: SpoonerismApp.self), "SpoonerismApp")
    }

    func test_homeCopyNamesTheJobWithoutEmDash() {
        XCTAssertEqual(MarrowCopy.spoonedJob, "Tap the swapped word")
        XCTAssertLessThanOrEqual(MarrowCopy.spoonedJob.split(separator: " ").count, 4)
        XCTAssertEqual(MarrowCopy.verb(sign: .spooned), MarrowCopy.spoonedJob)
        XCTAssertEqual(MarrowCopy.nextTap(sign: .spooned), MarrowCopy.spoonedNext)
        XCTAssertNotEqual(MarrowCopy.verb(sign: .spooned), MarrowCopy.nextTap(sign: .spooned))
        XCTAssertEqual(MarrowCopy.fluentHeadline, "Save a painting first.")
        let copy = userFacingCopy()
        for line in copy {
            XCTAssertFalse(line.contains("\u{2014}"))
            XCTAssertFalse(line.contains("\u{2013}"))
        }
    }

    func test_userCopyStaysOffTheNamingLexicon() {
        XCTAssertEqual(MarrowCopy.signLabel(.fluent), "Waiting")
        XCTAssertEqual(MarrowCopy.signLabel(.idle), "Ready")
        XCTAssertEqual(MarrowCopy.signLabel(.spooned), "Live")
        XCTAssertEqual(MarrowCopy.signLabel(.mended), "Filed")
        XCTAssertEqual(MarrowCopy.deviceSection, "This device")
        XCTAssertEqual(MarrowCopy.hitsMissesSection, "Hits and misses")
        XCTAssertEqual(MarrowCopy.recentHits, "Recent hits")
        XCTAssertEqual(MarrowCopy.hitsLabel, "Hits")
        XCTAssertEqual(MarrowCopy.missesLabel, "Misses")

        let forbidden = [
            "Onset",
            "Spooned",
            "Idle",
            "Mended",
            "Fluent",
            "MendMark",
            "MuffMark",
            "MendMarks",
            "MuffMarks",
            "marrowsky",
            "Marrowsky",
            "opening",
            " a head",
            "Hit a head",
        ]
        for line in userFacingCopy() {
            for token in forbidden {
                XCTAssertFalse(
                    line.contains(token),
                    "\(line) still prints naming lexicon \(token)"
                )
            }
        }
    }

    private func userFacingCopy() -> [String] {
        [
            MarrowCopy.fluentHeadline,
            MarrowCopy.fluentLine,
            MarrowCopy.exploreEmptyHeadline,
            MarrowCopy.exploreEmptyLine,
            MarrowCopy.savedEmptyHeadline,
            MarrowCopy.savedEmptyLine,
            MarrowCopy.spoonedJob,
            MarrowCopy.spoonedNext,
            MarrowCopy.writeFailed,
            MarrowCopy.recoverHeadline,
            MarrowCopy.recoverLine,
            MarrowCopy.deviceSection,
            MarrowCopy.hitsMissesSection,
            MarrowCopy.recentHits,
            MarrowCopy.hitsLabel,
            MarrowCopy.missesLabel,
            MarrowCopy.filedLabel,
            MarrowCopy.undoHint,
            MarrowCopy.verb(sign: .fluent),
            MarrowCopy.verb(sign: .idle),
            MarrowCopy.verb(sign: .spooned),
            MarrowCopy.verb(sign: .mended),
            MarrowCopy.nextTap(sign: .fluent),
            MarrowCopy.nextTap(sign: .idle),
            MarrowCopy.nextTap(sign: .spooned),
            MarrowCopy.nextTap(sign: .mended),
            MarrowCopy.signLabel(.fluent),
            MarrowCopy.signLabel(.idle),
            MarrowCopy.signLabel(.spooned),
            MarrowCopy.signLabel(.mended),
            MarrowCopy.fieldLabel(.artist),
            MarrowCopy.fieldLabel(.title),
            MarrowCopy.fault(OnsetFault.mendOnIdle),
            MarrowCopy.fault(OnsetFault.alreadySpooned),
            MarrowCopy.fault(OnsetFault.thinField),
            MarrowCopy.fault(OnsetFault.unknownHead),
            MarrowCopy.fault(OnsetFault.alreadyRighted),
            MarrowCopy.fault(OnsetFault.alreadyGrey),
            MarrowCopy.fault(OnsetFault.nothingToPeel),
        ]
    }
}
