import XCTest
@testable import Spoonerism

final class OnsetStoreTests: XCTestCase {
    private var directory: URL!
    private var suiteName: String!
    private var defaults: UserDefaults!
    private var calendar: Calendar { SpoonerismGMT.calendar }
    private var now: Date { SpoonerismGMT.instant(2026, 9, 19) }

    override func setUpWithError() throws {
        directory = FileManager.default.temporaryDirectory.appendingPathComponent(
            UUID().uuidString,
            isDirectory: true
        )
        suiteName = "spn.test.\(UUID().uuidString)"
        defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
    }

    override func tearDownWithError() throws {
        if let directory {
            try? FileManager.default.removeItem(at: directory)
        }
        if let suiteName {
            defaults?.removePersistentDomain(forName: suiteName)
        }
        directory = nil
        defaults = nil
        suiteName = nil
    }

    @MainActor
    func test_roundTrip_reloadPreservesHangingMarksAndHeads() async throws {
        let store = makeStore()
        await store.load()
        try await store.keepWork(Shelf.bundled.rows[1], now: now, calendar: calendar)
        try await store.spoonWork()
        let miss = try XCTUnwrap(store.onset.line?.heads.first { head in
            !(store.onset.line?.isSwapped(head.id) ?? true)
        })
        try await store.mend(miss.id, now: now, calendar: calendar)
        try await mendOnce(store)
        await store.flush()

        let relaunched = makeStore()
        await relaunched.load()
        XCTAssertNil(relaunched.warning)
        XCTAssertEqual(relaunched.onset.works.count, 1)
        XCTAssertEqual(relaunched.onset.hangingWork?.fold, .mended)
        XCTAssertEqual(relaunched.onset.mendMarks.count, 1)
        XCTAssertEqual(relaunched.onset.muffMarks.count, 1)
        XCTAssertEqual(relaunched.onset.sign, .mended)
        XCTAssertNotNil(defaults.data(forKey: OnsetKey.snapshot))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.appendingPathComponent("onset.json").path))
    }

    @MainActor
    func test_corruptSnapshotFallsBackToBackup() async throws {
        let store = makeStore()
        await store.load()
        try await store.keepWork(Shelf.bundled.rows[0], now: now, calendar: calendar)
        await store.flush()
        if let good = defaults.data(forKey: OnsetKey.snapshot) {
            defaults.set(good, forKey: OnsetKey.backup)
        }
        let file = directory.appendingPathComponent("onset.json")
        let backup = directory.appendingPathComponent("onset.json.backup")
        if FileManager.default.fileExists(atPath: file.path) {
            try? FileManager.default.removeItem(at: backup)
            try FileManager.default.copyItem(at: file, to: backup)
        }
        defaults.set(Data("{not-json".utf8), forKey: OnsetKey.snapshot)
        try Data("{not-json".utf8).write(to: file)

        let loaded = makeStore()
        await loaded.load()
        XCTAssertEqual(loaded.warning, .recoveredFromBackup)
        XCTAssertEqual(loaded.onset.works.count, 1)
    }

    @MainActor
    func test_corruptSnapshotWithoutBackupStartsEmpty() async throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defaults.set(Data("nope".utf8), forKey: OnsetKey.snapshot)
        try Data("nope".utf8).write(to: directory.appendingPathComponent("onset.json"))
        let store = makeStore()
        await store.load()
        XCTAssertEqual(store.warning, .startedEmpty)
        XCTAssertTrue(store.onset.works.isEmpty)
        XCTAssertFalse(store.onset.onboardingComplete)
    }

    func test_codecSwitchesOnSchemaVersion() throws {
        let onset = OnsetSeed.onset(now: now, calendar: calendar)
        let data = try OnsetDocument.encode(onset)
        let decoded = try OnsetDocument.decode(data)
        XCTAssertEqual(decoded.schemaVersion, 1)
        XCTAssertEqual(decoded.works.count, onset.works.count)
        XCTAssertEqual(decoded.line?.workID, onset.line?.workID)
        XCTAssertEqual(decoded.muffMarks.count, onset.muffMarks.count)
        XCTAssertTrue(decoded.works.contains { $0.fold == .mended })
        XCTAssertTrue(decoded.works.contains { $0.fold == .spooned })

        XCTAssertThrowsError(try OnsetDocument.decode(Data("{\"schemaVersion\":99}".utf8))) { error in
            XCTAssertEqual(error as? OnsetCodecError, .unsupportedSchema(99))
        }
        XCTAssertThrowsError(try OnsetDocument.decode(Data("[]".utf8))) { error in
            XCTAssertEqual(error as? OnsetCodecError, .corrupt)
        }
    }

    @MainActor
    func test_resetAllDataClearsSnapshotAndFiles() async throws {
        let store = makeStore()
        await store.load()
        try await store.keepWork(Shelf.bundled.rows[0], now: now, calendar: calendar)
        await store.flush()
        await store.resetAllData()
        await store.load()
        XCTAssertTrue(store.onset.works.isEmpty)
        XCTAssertFalse(store.onset.onboardingComplete)
        XCTAssertNil(defaults.data(forKey: OnsetKey.snapshot))
        XCTAssertNil(defaults.data(forKey: OnsetKey.backup))
        let leftovers = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        XCTAssertTrue(leftovers.filter { $0.pathExtension == "json" }.isEmpty)
    }

    @MainActor
    func test_onboardingFlagDebouncesUntilFlush() async throws {
        let store = makeStore()
        await store.load()
        await store.setOnboardingComplete(true)
        await store.flush()
        let loaded = makeStore()
        await loaded.load()
        XCTAssertTrue(loaded.onset.onboardingComplete)
    }

    #if targetEnvironment(simulator)
    @MainActor
    func test_simulatorSeedWritesOnceAndEnablesMend() async throws {
        let store = makeStore()
        await store.seedDemoIfNeeded(now: now, calendar: calendar)
        let firstWorks = store.onset.works.count
        await store.seedDemoIfNeeded(now: now, calendar: calendar)
        XCTAssertEqual(store.onset.works.count, firstWorks)
        XCTAssertTrue(store.onset.onboardingComplete)
        XCTAssertTrue(store.onset.canMend)
        XCTAssertEqual(store.onset.hangingWork?.fold, .spooned)
        XCTAssertNotEqual(store.onset.sign, .fluent)
        XCTAssertGreaterThanOrEqual(store.onset.works.count, 6)
        XCTAssertTrue(defaults.bool(forKey: OnsetKey.demo))
        XCTAssertNotNil(defaults.data(forKey: OnsetKey.snapshot))
    }
    #endif

    @MainActor
    func test_seekFiltersBundledShelf() async throws {
        let store = makeStore()
        await store.load()
        let goya = try await store.seek("goya")
        XCTAssertFalse(goya.isEmpty)
        XCTAssertTrue(goya.allSatisfy { $0.artist.localizedCaseInsensitiveContains("goya") })
    }

    @MainActor
    func test_seekFallsBackToLocalShelfWhenLookupIsEmpty() async throws {
        let store = makeStore()
        await store.load()
        let rows = try await store.seek("no-such-painter")
        XCTAssertEqual(rows.first?.title, Shelf.bundled.rows[0].title)
        XCTAssertGreaterThanOrEqual(rows.count, 8)
    }

    @MainActor
    func test_emptyQueryStaysOnBundledShelf() async throws {
        let store = makeStore()
        let rows = try await store.seek("   ")
        XCTAssertFalse(rows.isEmpty)
        XCTAssertEqual(rows.count, Shelf.bundled.rows.count)
    }

    @MainActor
    private func makeStore(client: CatalogClient = CatalogClient()) -> OnsetStore {
        OnsetStore(
            directory: directory,
            suiteName: suiteName,
            client: client,
            picker: FixedFieldPicker(field: .title),
            pairing: FirstLastPairing(),
            shelf: .bundled,
            writeDelayNanoseconds: 0,
            seekDelayNanoseconds: 0
        )
    }

    @MainActor
    private func mendOnce(_ store: OnsetStore) async throws {
        let head = try XCTUnwrap(store.onset.line?.openSwapped.first)
        try await store.mend(head.id, now: now, calendar: calendar)
    }
}
