import Foundation
import Observation

/// Role: Onset. Observable fold owner. Memory is the source of truth. UserDefaults is the projection. Views call spoonWork, mend, and undoNewest.
@MainActor
@Observable
final class OnsetStore {
    static let seekDebounceNanoseconds: UInt64 = 300_000_000

    private(set) var onset: Onset
    private(set) var warning: OnsetWarning?
    private(set) var lastWriteError: String?

    private let vault: OnsetVault
    private let client: CatalogClient
    private let picker: any FieldPicking
    private let pairing: any HeadPairing
    private let shelf: Shelf
    private let writeDelayNanoseconds: UInt64
    private let seekDelayNanoseconds: UInt64
    private var persistTask: Task<Void, Never>?
    private var seekTask: Task<[CatalogRow], Error>?

    init(
        directory: URL,
        suiteName: String? = nil,
        client: CatalogClient = CatalogClient(),
        picker: any FieldPicking = AlternatingFieldPicker(),
        pairing: any HeadPairing = SaltPairing(),
        shelf: Shelf = .bundled,
        writeDelayNanoseconds: UInt64 = 280_000_000,
        seekDelayNanoseconds: UInt64 = OnsetStore.seekDebounceNanoseconds
    ) {
        self.vault = OnsetVault(directory: directory, suiteName: suiteName)
        self.client = client
        self.picker = picker
        self.pairing = pairing
        self.shelf = shelf
        self.writeDelayNanoseconds = writeDelayNanoseconds
        self.seekDelayNanoseconds = seekDelayNanoseconds
        self.onset = .empty
        self.warning = nil
        self.lastWriteError = nil
    }

    convenience init() {
        let directory: URL
        do {
            directory = try OnsetVault.applicationSupportDirectory()
        } catch {
            directory = FileManager.default.temporaryDirectory.appendingPathComponent("Spoonerism", isDirectory: true)
        }
        self.init(directory: directory)
    }

    func load() async {
        let loaded = await vault.load()
        onset = loaded.onset
        warning = loaded.warning
        lastWriteError = nil
    }

    func spoonWork() async throws {
        var next = onset
        try next.spoonWork(picker: picker, pairing: pairing)
        onset = next
        await persistNow()
    }

    func mend(_ headID: UUID, now: Date = Date(), calendar: Calendar = .current) async throws {
        var next = onset
        _ = try next.mend(headID, now: now, calendar: calendar)
        onset = next
        await persistNow()
    }

    func undoNewest() async throws {
        var next = onset
        try next.undoNewest()
        onset = next
        await persistNow()
    }

    @discardableResult
    func keepWork(_ row: CatalogRow, now: Date = Date(), calendar: Calendar = .current) async throws -> WriteFocus {
        var next = onset
        let focus = try next.keepWork(row, now: now, calendar: calendar)
        onset = next
        await persistNow()
        return focus
    }

    func seek(_ query: String) async throws -> [CatalogRow] {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return onset.fallbackRows(shelf: shelf.rows)
        }
        let client = self.client
        let shelfRows = shelf.rows
        let delay = seekDelayNanoseconds
        let task = Task { () throws -> [CatalogRow] in
            if delay > 0 {
                try await Task.sleep(nanoseconds: delay)
            }
            try Task.checkCancellation()
            return await client.search(query: trimmed, shelf: shelfRows)
        }
        seekTask = task
        do {
            let rows = try await task.value
            if Task.isCancelled { throw CatalogFault.cancelled }
            if rows.isEmpty {
                return onset.fallbackRows(shelf: shelf.rows)
            }
            var next = onset
            next.remember(rows)
            onset = next
            await persistNow()
            return rows
        } catch is CancellationError {
            throw CatalogFault.cancelled
        } catch let fault as CatalogFault where fault == .cancelled {
            throw fault
        } catch {
            return onset.fallbackRows(shelf: shelf.rows)
        }
    }

    func setOnboardingComplete(_ flag: Bool) async {
        var next = onset
        next.setOnboardingComplete(flag)
        onset = next
        schedulePersist()
    }

    func flush() async {
        persistTask?.cancel()
        persistTask = nil
        await persistNow()
    }

    func resetAllData() async {
        persistTask?.cancel()
        persistTask = nil
        onset = .empty
        warning = nil
        lastWriteError = nil
        do {
            try await vault.wipe()
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    func seedDemoIfNeeded(now: Date = Date(), calendar: Calendar = .current) async {
        #if targetEnvironment(simulator)
        if await vault.demoPlanted() { return }
        onset = OnsetSeed.onset(now: now, calendar: calendar, picker: picker, pairing: pairing, shelf: shelf.rows)
        await vault.markDemoPlanted()
        await persistNow()
        #else
        _ = now
        _ = calendar
        #endif
    }

    private func persistNow() async {
        do {
            try await vault.save(onset)
            lastWriteError = nil
        } catch {
            lastWriteError = String(describing: error)
        }
    }

    private func schedulePersist() {
        persistTask?.cancel()
        let delay = writeDelayNanoseconds
        persistTask = Task { [weak self] in
            if delay > 0 {
                try? await Task.sleep(nanoseconds: delay)
            }
            guard !Task.isCancelled else { return }
            await self?.persistNow()
        }
    }
}
