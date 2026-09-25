import Foundation

/// Role: Onset. Status chrome. IDLE, SPOONED, MENDED, FLUENT. Fluent is an onset write, never a fourth WorkFold case.
enum OnsetSign: String, Codable, Sendable, Equatable {
    case fluent
    case idle
    case spooned
    case mended
}

/// Role: Onset. Hanging of the fold over Works. Fluent is an onset write, never a fourth WorkFold case.
enum OnsetHang: Equatable, Sendable {
    case fluent
    case idle
    case spooned(Line)
    case mended(Line)
}

extension OnsetHang: Codable {
    enum Kind: String, Codable, Sendable {
        case fluent
        case idle
        case spooned
        case mended
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case line
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .fluent:
            try container.encode(Kind.fluent, forKey: .kind)
        case .idle:
            try container.encode(Kind.idle, forKey: .kind)
        case .spooned(let line):
            try container.encode(Kind.spooned, forKey: .kind)
            try container.encode(line, forKey: .line)
        case .mended(let line):
            try container.encode(Kind.mended, forKey: .kind)
            try container.encode(line, forKey: .line)
        }
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(Kind.self, forKey: .kind)
        switch kind {
        case .fluent:
            self = .fluent
        case .idle:
            self = .idle
        case .spooned:
            self = .spooned(try container.decode(Line.self, forKey: .line))
        case .mended:
            self = .mended(try container.decode(Line.self, forKey: .line))
        }
    }
}

/// Role: Onset. Typed refusals of Spoon, Mend, and Undo. Views map these.
enum OnsetFault: Error, Equatable, Sendable {
    case mendOnIdle
    case alreadySpooned
    case thinField
    case unknownHead
    case alreadyRighted
    case alreadyGrey
    case nothingToPeel
    case emptyObjectID
    case unknownWork
}

/// Role: Onset. Ordered undo stack. Undo peels the newest MendMark or MuffMark.
enum PeelKind: String, Codable, Sendable {
    case mend
    case muff
}

struct PeelRef: Equatable, Sendable, Codable {
    var kind: PeelKind
    var headID: UUID?
    var markID: UUID?
}

/// Role: Onset. Explore save outcome. Duplicate object id focuses and does not reset the fold.
enum WriteFocus: Equatable, Sendable {
    case inserted(UUID)
    case focused(UUID)
}

/// Role: Onset. Recoverable load outcome. Never crash on a corrupt snapshot.
enum OnsetWarning: Equatable, Sendable {
    case recoveredFromBackup
    case startedEmpty
}

/// Role: Onset. Strike of one Head. Mend rights both swapped openings. Muff greys a clean word.
enum HeadStrike: Equatable, Sendable {
    case mend(MendMark)
    case muff(MuffMark)
}

/// Role: Onset. In-memory fold over Works. Views call spoonWork, mend, and undoNewest. Never a second fold enum.
struct Onset: Equatable, Sendable {
    var schemaVersion: Int
    var onboardingComplete: Bool
    var works: [Work]
    var hanging: OnsetHang
    var mendMarks: [MendMark]
    var muffMarks: [MuffMark]
    var peelLog: [PeelRef]
    var cachedRows: [CatalogRow]
    var focusedWorkID: UUID?

    static let currentSchema = 1

    static let empty = Onset(
        schemaVersion: currentSchema,
        onboardingComplete: false,
        works: [],
        hanging: .fluent,
        mendMarks: [],
        muffMarks: [],
        peelLog: [],
        cachedRows: [],
        focusedWorkID: nil
    )

    var spoonPool: [Work] {
        works.filter { !$0.fold.isMended }
    }

    var mendedWorks: [Work] {
        works.filter(\.fold.isMended)
    }

    var reviewableMuffs: [MuffMark] {
        muffMarks
    }

    var reviewableMends: [MendMark] {
        mendMarks
    }

    var hangingWork: Work? {
        guard let line else { return nil }
        return works.first { $0.id == line.workID }
    }

    var line: Line? {
        switch hanging {
        case .fluent, .idle:
            return nil
        case .spooned(let line), .mended(let line):
            return line
        }
    }

    var sign: OnsetSign {
        switch hanging {
        case .fluent:
            return .fluent
        case .idle:
            return .idle
        case .spooned:
            return .spooned
        case .mended:
            return .mended
        }
    }

    var canSpoon: Bool {
        if case .spooned = hanging { return false }
        return true
    }

    var canMend: Bool {
        guard case .spooned(let line) = hanging else { return false }
        return !line.openSwapped.isEmpty
    }

    mutating func spoonWork(
        picker: any FieldPicking,
        pairing: any HeadPairing,
        headIDs: [UUID]? = nil
    ) throws {
        if case .spooned = hanging {
            throw OnsetFault.alreadySpooned
        }
        let pool = spoonPool.sorted { lhs, rhs in
            if lhs.daykey != rhs.daykey { return lhs.daykey < rhs.daykey }
            return lhs.objectID < rhs.objectID
        }
        for chosen in pool {
            let field = picker.field(for: chosen)
            if HeadCut.qualifies(HeadCut.fieldText(chosen, field)) {
                try applySpoon(chosen, field: field, pairing: pairing, headIDs: headIDs)
                return
            }
        }
        hanging = .fluent
    }

    @discardableResult
    mutating func mend(
        _ headID: UUID,
        markID: UUID = UUID(),
        now: Date,
        calendar: Calendar
    ) throws -> HeadStrike {
        switch hanging {
        case .fluent, .idle, .mended:
            throw OnsetFault.mendOnIdle
        case .spooned(let line):
            guard let head = line.head(id: headID) else {
                throw OnsetFault.unknownHead
            }
            if line.isSwapped(headID) && !head.isRighted {
                return try fileMend(head: head, line: line, markID: markID, now: now, calendar: calendar)
            }
            if head.isGrey {
                throw OnsetFault.alreadyGrey
            }
            if head.isRighted {
                throw OnsetFault.alreadyRighted
            }
            return try fileMuff(head: head, line: line, markID: markID, now: now, calendar: calendar)
        }
    }

    mutating func undoNewest() throws {
        guard let last = peelLog.popLast() else {
            throw OnsetFault.nothingToPeel
        }
        switch last.kind {
        case .mend:
            peelMend(markID: last.markID, headID: last.headID)
        case .muff:
            peelMuff(markID: last.markID, headID: last.headID)
        }
    }

    @discardableResult
    mutating func keepWork(
        _ row: CatalogRow,
        now: Date,
        calendar: Calendar,
        id: UUID = UUID()
    ) throws -> WriteFocus {
        let objectID = row.objectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !objectID.isEmpty else { throw OnsetFault.emptyObjectID }
        if let existing = works.first(where: { $0.objectID == objectID }) {
            focusedWorkID = existing.id
            return .focused(existing.id)
        }
        var incoming = row
        incoming.objectID = objectID
        let work = Work.idle(from: incoming, id: id, daykey: Daykey.stamp(now, calendar: calendar))
        works.append(work)
        remember(incoming)
        focusedWorkID = work.id
        if case .fluent = hanging {
            hanging = .idle
        }
        return .inserted(work.id)
    }

    mutating func remember(_ rows: [CatalogRow]) {
        for row in rows {
            remember(row)
        }
    }

    mutating func remember(_ row: CatalogRow) {
        let objectID = row.objectID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !objectID.isEmpty else { return }
        var stored = row
        stored.objectID = objectID
        if let index = cachedRows.firstIndex(where: { $0.objectID == objectID }) {
            cachedRows[index] = stored
        } else {
            cachedRows.append(stored)
        }
    }

    mutating func setOnboardingComplete(_ flag: Bool) {
        onboardingComplete = flag
    }

    mutating func resetAllData() {
        self = .empty
    }

    func fallbackRows(shelf: [CatalogRow]) -> [CatalogRow] {
        var seen = Set<String>()
        var merged: [CatalogRow] = []
        for row in cachedRows + shelf {
            if seen.insert(row.objectID).inserted {
                merged.append(row)
            }
        }
        return merged
    }

    private mutating func applySpoon(
        _ chosen: Work,
        field: LineField,
        pairing: any HeadPairing,
        headIDs: [UUID]?
    ) throws {
        for index in works.indices where works[index].fold == .spooned && works[index].id != chosen.id {
            works[index].fold = .idle
        }
        guard let workIndex = works.firstIndex(where: { $0.id == chosen.id }) else {
            throw OnsetFault.unknownWork
        }
        let line = try LinePress.make(
            work: works[workIndex],
            field: field,
            pairing: pairing,
            headIDs: headIDs
        )
        works[workIndex].fold = .spooned
        hanging = .spooned(line)
        focusedWorkID = chosen.id
    }

    private mutating func fileMend(
        head: Head,
        line: Line,
        markID: UUID,
        now: Date,
        calendar: Calendar
    ) throws -> HeadStrike {
        var next = line
        next.rightBoth()
        guard let workIndex = works.firstIndex(where: { $0.id == next.workID }) else {
            throw OnsetFault.unknownWork
        }
        let mark = MendMark(
            id: markID,
            workID: next.workID,
            field: next.field,
            headID: head.id,
            seat: head.seat,
            opening: head.nativeOpening,
            daykey: Daykey.stamp(now, calendar: calendar)
        )
        mendMarks.append(mark)
        peelLog.append(PeelRef(kind: .mend, headID: head.id, markID: markID))
        focusedWorkID = next.workID
        works[workIndex].fold = .mended
        hanging = .mended(next)
        return .mend(mark)
    }

    private mutating func fileMuff(
        head: Head,
        line: Line,
        markID: UUID,
        now: Date,
        calendar: Calendar
    ) throws -> HeadStrike {
        var next = line
        next.grey(head.id)
        let mark = MuffMark(
            id: markID,
            workID: next.workID,
            field: next.field,
            headID: head.id,
            seat: head.seat,
            spoken: head.spoken,
            daykey: Daykey.stamp(now, calendar: calendar)
        )
        muffMarks.append(mark)
        peelLog.append(PeelRef(kind: .muff, headID: head.id, markID: markID))
        hanging = .spooned(next)
        focusedWorkID = next.workID
        return .muff(mark)
    }

    private mutating func peelMend(markID: UUID?, headID: UUID?) {
        let mark: MendMark?
        if let markID, let index = mendMarks.firstIndex(where: { $0.id == markID }) {
            mark = mendMarks.remove(at: index)
        } else if let headID, let index = mendMarks.lastIndex(where: { $0.headID == headID }) {
            mark = mendMarks.remove(at: index)
        } else {
            mark = nil
        }
        let workID = mark?.workID ?? line?.workID
        if let workID, let workIndex = works.firstIndex(where: { $0.id == workID }) {
            if works[workIndex].fold == .mended {
                switch hanging {
                case .spooned(let live) where live.workID == workID:
                    works[workIndex].fold = .spooned
                case .mended(let live) where live.workID == workID:
                    works[workIndex].fold = .spooned
                default:
                    works[workIndex].fold = .idle
                }
            }
        }
        switch hanging {
        case .spooned(var live) where workID == nil || live.workID == workID:
            live.rewearSwap()
            hanging = .spooned(live)
        case .mended(var live) where workID == nil || live.workID == workID:
            live.rewearSwap()
            hanging = .spooned(live)
        default:
            break
        }
    }

    private mutating func peelMuff(markID: UUID?, headID: UUID?) {
        if let markID, let index = muffMarks.firstIndex(where: { $0.id == markID }) {
            muffMarks.remove(at: index)
        } else if let headID, let index = muffMarks.lastIndex(where: { $0.headID == headID }) {
            muffMarks.remove(at: index)
        }
        let target = headID
        switch hanging {
        case .spooned(var live):
            if let target {
                live.ungrey(target)
            }
            hanging = .spooned(live)
        case .mended(var live):
            if let target {
                live.ungrey(target)
            }
            hanging = .mended(live)
        default:
            break
        }
    }
}
