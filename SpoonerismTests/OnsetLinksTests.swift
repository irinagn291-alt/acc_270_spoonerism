import XCTest
@testable import Spoonerism

final class OnsetLinksTests: XCTestCase {
    func test_readsOnceAfterOnboarding() {
        var consumed = false
        XCTAssertNil(
            OnsetLinks.consume(
                arguments: ["-ReviewScreen", "log"],
                onboardingComplete: false,
                consumed: &consumed
            )
        )
        XCTAssertFalse(consumed)

        let first = OnsetLinks.consume(
            arguments: ["app", "-ReviewScreen", "log"],
            onboardingComplete: true,
            consumed: &consumed
        )
        XCTAssertEqual(first, .log)
        XCTAssertEqual(first?.sheet, .saved)
        XCTAssertTrue(consumed)
        XCTAssertNil(
            OnsetLinks.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
    }

    func test_threeKeysAreDistinctScreensPlusExplore() {
        XCTAssertEqual(ReviewHook.today.rawValue, "today")
        XCTAssertEqual(ReviewHook.log.rawValue, "log")
        XCTAssertEqual(ReviewHook.goals.rawValue, "goals")
        XCTAssertEqual(ReviewHook.explore.rawValue, "explore")
        XCTAssertEqual(ReviewHook.today.sheet, .quiz)
        XCTAssertEqual(ReviewHook.log.sheet, .saved)
        XCTAssertEqual(ReviewHook.goals.sheet, .settings)
        XCTAssertEqual(ReviewHook.explore.sheet, .explore)
        XCTAssertNotEqual(ReviewHook.today.sheet, ReviewHook.log.sheet)
        XCTAssertNotEqual(ReviewHook.log.sheet, ReviewHook.goals.sheet)
        XCTAssertNotEqual(ReviewHook.today.sheet, ReviewHook.goals.sheet)
        XCTAssertNotEqual(ReviewHook.explore.sheet, ReviewHook.today.sheet)
        XCTAssertEqual(Set(OnsetSheet.allCases.map(\.rawValue)).count, 4)
        XCTAssertFalse(OnsetSheet.allCases.map(\.rawValue).contains("game"))

        var consumed = false
        XCTAssertEqual(
            OnsetLinks.consume(
                arguments: ["-ReviewScreen", "today"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .today
        )
        consumed = false
        XCTAssertEqual(
            OnsetLinks.consume(
                arguments: ["-ReviewScreen", "goals"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .goals
        )
        consumed = false
        XCTAssertEqual(
            OnsetLinks.consume(
                arguments: ["-ReviewScreen", "explore"],
                onboardingComplete: true,
                consumed: &consumed
            ),
            .explore
        )
    }

    func test_unknownKeyIsIgnored() {
        var consumed = false
        XCTAssertNil(
            OnsetLinks.consume(
                arguments: ["-ReviewScreen", "aura"],
                onboardingComplete: true,
                consumed: &consumed
            )
        )
        XCTAssertTrue(consumed)
    }
}
