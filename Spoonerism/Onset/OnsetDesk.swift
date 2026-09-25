import Foundation
import Observation
import SwiftUI

/// Role: Onset. Presented sheet over the locked Quiz. Quiz itself never leaves. Twist is a fifth destination, never a Game tab.
enum MarrowCover: String, Identifiable, Equatable, Sendable {
    case explore
    case saved
    case settings
    case spoonMend

    var id: String { rawValue }
}

/// Role: Onset. Presentation fold over OnsetStore. Views call spoonWork, mend, and undoNewest and never keep a second Onset enum.
@MainActor
@Observable
final class OnsetDesk {
    let store: OnsetStore
    private(set) var onset: Onset
    var isBooting: Bool
    var showsOnboarding: Bool
    var cover: MarrowCover?
    var recoveredNotice: Bool
    var isSpooning: Bool
    var spoonBusy: Bool
    var isUndoing: Bool
    var undoBusy: Bool
    var mendBusy: UUID?
    var isSeeking: Bool
    var query: String
    var seekHits: [CatalogRow]
    var seekFault: String?
    var onsetFault: String?
    var shelfNote: String?
    var stockingObjectID: String?
    var mendPulse: Int
    var showSuccess: Bool
    var dayStamp: Int
    private var cueConsumed: Bool
    private var seekTask: Task<Void, Never>?
    private var successTask: Task<Void, Never>?

    init(store: OnsetStore, isBooting: Bool = true) {
        self.store = store
        self.onset = store.onset
        self.isBooting = isBooting
        self.showsOnboarding = false
        self.cover = nil
        self.recoveredNotice = false
        self.isSpooning = false
        self.spoonBusy = false
        self.isUndoing = false
        self.undoBusy = false
        self.mendBusy = nil
        self.isSeeking = false
        self.query = ""
        self.seekHits = []
        self.seekFault = nil
        self.onsetFault = nil
        self.shelfNote = nil
        self.stockingObjectID = nil
        self.mendPulse = 0
        self.showSuccess = false
        self.dayStamp = Daykey.stamp(Date(), calendar: .current)
        self.cueConsumed = false
    }

    static func live() -> OnsetDesk {
        OnsetDesk(store: OnsetStore())
    }

    func boot() async {
        guard isBooting else { return }
        await store.load()
        await store.seedDemoIfNeeded()
        sync()
        recoveredNotice = store.warning != nil
        showsOnboarding = !onset.onboardingComplete
        isBooting = false
        if query.isEmpty {
            seekHits = onset.fallbackRows(shelf: Shelf.bundled.rows)
        }
        if !showsOnboarding {
            consumeCue()
        }
    }

    func flush() async {
        await store.flush()
        sync()
    }

    func refreshDay() {
        dayStamp = Daykey.stamp(Date(), calendar: .current)
    }

    func handle(phase: ScenePhase) async {
        switch phase {
        case .inactive, .background:
            await flush()
        case .active:
            refreshDay()
        @unknown default:
            break
        }
    }

    func finishOnboarding() async {
        await store.setOnboardingComplete(true)
        await store.flush()
        sync()
        showsOnboarding = false
        consumeCue()
    }

    func replayOnboarding() {
        cover = nil
        showsOnboarding = true
        Task {
            await store.setOnboardingComplete(false)
            await store.flush()
            sync()
        }
    }

    func present(_ cover: MarrowCover) {
        self.cover = cover
    }

    func spoonWork() async {
        guard !isSpooning else { return }
        isSpooning = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { spoonBusy = true }
        }
        do {
            try await store.spoonWork()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                onsetFault = nil
            }
        } catch {
            onsetFault = MarrowCopy.fault(error)
            sync()
        }
        pulse.cancel()
        spoonBusy = false
        isSpooning = false
        sync()
    }

    func mend(_ headID: UUID) async {
        guard mendBusy == nil else { return }
        mendBusy = headID
        let mendCount = onset.mendMarks.count
        do {
            try await store.mend(headID)
            sync()
            if onset.mendMarks.count > mendCount {
                mendPulse += 1
            }
            if case .mended = onset.hanging {
                flashSuccess()
            }
            if store.lastWriteError == nil {
                onsetFault = nil
            }
        } catch {
            onsetFault = MarrowCopy.fault(error)
            sync()
        }
        mendBusy = nil
        sync()
    }

    func undoNewest() async {
        guard !isUndoing else { return }
        isUndoing = true
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { undoBusy = true }
        }
        do {
            try await store.undoNewest()
            showSuccess = false
            sync()
            if store.lastWriteError == nil {
                onsetFault = nil
            }
        } catch {
            onsetFault = MarrowCopy.fault(error)
            sync()
        }
        pulse.cancel()
        undoBusy = false
        isUndoing = false
        sync()
    }

    func keepWork(_ row: CatalogRow) async {
        guard stockingObjectID == nil else { return }
        stockingObjectID = row.objectID
        do {
            let focus = try await store.keepWork(row)
            sync()
            switch focus {
            case .inserted:
                shelfNote = "Kept."
            case .focused:
                shelfNote = "Already kept."
            }
            onsetFault = nil
        } catch {
            shelfNote = MarrowCopy.fault(error)
        }
        stockingObjectID = nil
        if store.lastWriteError != nil {
            onsetFault = MarrowCopy.writeFailed
        }
    }

    func scheduleSeek() {
        seekTask?.cancel()
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        seekTask = Task { await seek(trimmed) }
    }

    func resetAllData() async {
        seekTask?.cancel()
        successTask?.cancel()
        await store.resetAllData()
        sync()
        cover = nil
        query = ""
        seekHits = onset.fallbackRows(shelf: Shelf.bundled.rows)
        seekFault = nil
        onsetFault = nil
        shelfNote = nil
        recoveredNotice = false
        showSuccess = false
        showsOnboarding = true
        cueConsumed = true
    }

    func work(for id: UUID?) -> Work? {
        guard let id else { return nil }
        return onset.works.first { $0.id == id }
    }

    func work(for mark: MendMark) -> Work? {
        work(for: mark.workID)
    }

    func work(for mark: MuffMark) -> Work? {
        work(for: mark.workID)
    }

    var displayedWork: Work? {
        onset.hangingWork ?? work(for: onset.focusedWorkID) ?? onset.spoonPool.first ?? onset.works.first
    }

    var spoonEnabled: Bool {
        onset.canSpoon && !isSpooning && onset.sign != .fluent
    }

    var undoEnabled: Bool {
        !onset.peelLog.isEmpty && !isUndoing
    }

    var quizIsEmpty: Bool {
        onset.sign == .fluent
    }

    var savedIsEmpty: Bool {
        onset.mendedWorks.isEmpty && onset.reviewableMends.isEmpty && onset.reviewableMuffs.isEmpty
    }

    var exploreIsEmpty: Bool {
        seekHits.isEmpty && !isSeeking
    }

    var settingsIsEmpty: Bool {
        onset.works.isEmpty && onset.mendMarks.isEmpty && onset.muffMarks.isEmpty
    }

    var focusedObjectID: String? {
        guard let focused = work(for: onset.focusedWorkID) else { return nil }
        return focused.objectID
    }

    private func seek(_ trimmed: String) async {
        if trimmed.isEmpty {
            isSeeking = false
            seekFault = nil
            do {
                seekHits = try await store.seek("")
            } catch is CancellationError {
                return
            } catch {
                seekHits = onset.fallbackRows(shelf: Shelf.bundled.rows)
            }
            return
        }
        let pulse = Task {
            try await Task.sleep(for: .milliseconds(150))
            if !Task.isCancelled { isSeeking = true }
        }
        defer {
            pulse.cancel()
            isSeeking = false
        }
        do {
            let hits = try await store.seek(trimmed)
            if Task.isCancelled { return }
            sync()
            seekHits = hits
            if hits.isEmpty {
                seekFault = MarrowCopy.seek(.missing)
            } else {
                seekFault = nil
            }
        } catch is CancellationError {
            return
        } catch let fault as CatalogFault where fault == .cancelled {
            return
        } catch let fault as CatalogFault {
            if Task.isCancelled { return }
            sync()
            seekHits = onset.fallbackRows(shelf: Shelf.bundled.rows)
            seekFault = MarrowCopy.seek(fault)
        } catch {
            if Task.isCancelled { return }
            sync()
            seekHits = onset.fallbackRows(shelf: Shelf.bundled.rows)
            seekFault = MarrowCopy.seek(.transport)
        }
    }

    private func flashSuccess() {
        successTask?.cancel()
        showSuccess = true
        successTask = Task {
            try? await Task.sleep(for: .milliseconds(1200))
            if !Task.isCancelled {
                showSuccess = false
            }
        }
    }

    private func sync() {
        onset = store.onset
        if let write = store.lastWriteError, !write.isEmpty {
            onsetFault = MarrowCopy.writeFailed
        }
    }

    private func consumeCue() {
        if let hook = OnsetLinks.consume(
            arguments: ProcessInfo.processInfo.arguments,
            onboardingComplete: onset.onboardingComplete,
            consumed: &cueConsumed
        ) {
            switch hook.sheet {
            case .quiz:
                cover = nil
            case .explore:
                cover = .explore
            case .saved:
                cover = .saved
            case .settings:
                cover = .settings
            }
        }
    }
}
