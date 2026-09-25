import Foundation

/// Role: Line. QuizCard. Artist XOR title with two openings exchanged and every seat left in place.
struct Line: Equatable, Sendable, Codable {
    var workID: UUID
    var field: LineField
    var heads: [Head]
    var leftID: UUID
    var rightID: UUID

    var swappedIDs: Set<UUID> {
        [leftID, rightID]
    }

    var openSwapped: [Head] {
        heads.filter { swappedIDs.contains($0.id) && !$0.isRighted }
    }

    var isFullyRighted: Bool {
        openSwapped.isEmpty && heads.contains { swappedIDs.contains($0.id) }
    }

    func head(id: UUID) -> Head? {
        heads.first { $0.id == id }
    }

    func isSwapped(_ id: UUID) -> Bool {
        id == leftID || id == rightID
    }

    func partnerID(of id: UUID) -> UUID? {
        if id == leftID { return rightID }
        if id == rightID { return leftID }
        return nil
    }

    mutating func rightBoth() {
        rightOne(leftID)
        rightOne(rightID)
    }

    mutating func rewearSwap() {
        guard let left = head(id: leftID), let right = head(id: rightID) else { return }
        wear(leftID, opening: right.nativeOpening, righted: false)
        wear(rightID, opening: left.nativeOpening, righted: false)
    }

    mutating func grey(_ id: UUID) {
        guard let index = heads.firstIndex(where: { $0.id == id }) else { return }
        heads[index].isGrey = true
    }

    mutating func ungrey(_ id: UUID) {
        guard let index = heads.firstIndex(where: { $0.id == id }) else { return }
        heads[index].isGrey = false
    }

    private mutating func rightOne(_ id: UUID) {
        guard let index = heads.firstIndex(where: { $0.id == id }) else { return }
        heads[index].wornOpening = heads[index].nativeOpening
        heads[index].isRighted = true
    }

    private mutating func wear(_ id: UUID, opening: String, righted: Bool) {
        guard let index = heads.firstIndex(where: { $0.id == id }) else { return }
        heads[index].wornOpening = opening
        heads[index].isRighted = righted
    }
}

/// Role: Line. Artist XOR title. Never both fields on one Line.
enum LineField: String, Equatable, Sendable, Codable {
    case artist
    case title

    var toggled: LineField {
        self == .artist ? .title : .artist
    }
}

/// Role: Line. Picks artist XOR title for this Spoon.
protocol FieldPicking: Sendable {
    func field(for work: Work) -> LineField
}

struct AlternatingFieldPicker: FieldPicking {
    func field(for work: Work) -> LineField {
        let preferred: LineField = work.id.uuid.0.isMultiple(of: 2) ? .artist : .title
        if HeadCut.qualifies(HeadCut.fieldText(work, preferred)) {
            return preferred
        }
        return preferred.toggled
    }
}

struct FixedFieldPicker: FieldPicking {
    var field: LineField

    func field(for work: Work) -> LineField {
        _ = work
        return field
    }
}

/// Role: Line. Chooses the two seats whose openings trade.
protocol HeadPairing: Sendable {
    func pair(from seats: [Int], salt: Int) -> (Int, Int)?
}

struct FirstLastPairing: HeadPairing {
    func pair(from seats: [Int], salt: Int) -> (Int, Int)? {
        _ = salt
        guard let first = seats.first, let last = seats.last, first != last else {
            return nil
        }
        return (first, last)
    }
}

struct SaltPairing: HeadPairing {
    func pair(from seats: [Int], salt: Int) -> (Int, Int)? {
        guard seats.count >= 2 else { return nil }
        let i = abs(salt) % seats.count
        var j = abs(salt / 7) % seats.count
        if j == i {
            j = (i + 1) % seats.count
        }
        let left = min(seats[i], seats[j])
        let right = max(seats[i], seats[j])
        if left == right { return nil }
        return (left, right)
    }
}

/// Role: Line. Builds a live Line from a Work field. Tests pin seats through HeadPairing.
enum LinePress {
    static func make(
        work: Work,
        field: LineField,
        pairing: any HeadPairing,
        headIDs: [UUID]? = nil
    ) throws -> Line {
        let text = HeadCut.fieldText(work, field)
        let pieces = HeadCut.pieces(in: text)
        let distinct = HeadCut.distinctSeats(in: pieces)
        guard distinct.count >= 2 else {
            throw OnsetFault.thinField
        }
        let salt = Int(work.id.uuid.0) &+ Int(work.id.uuid.1)
        guard let pair = pairing.pair(from: distinct, salt: salt) else {
            throw OnsetFault.thinField
        }
        var heads: [Head] = pieces.enumerated().map { offset, piece in
            let id: UUID
            if let headIDs, offset < headIDs.count {
                id = headIDs[offset]
            } else {
                id = UUID()
            }
            return Head(
                id: id,
                seat: offset,
                prefix: piece.prefix,
                nativeOpening: piece.opening,
                wornOpening: piece.opening,
                stem: piece.stem,
                isRighted: false,
                isGrey: false
            )
        }
        let left = pair.0
        let right = pair.1
        guard heads.indices.contains(left), heads.indices.contains(right) else {
            throw OnsetFault.thinField
        }
        let leftOpening = heads[left].nativeOpening
        let rightOpening = heads[right].nativeOpening
        heads[left].wornOpening = rightOpening
        heads[right].wornOpening = leftOpening
        return Line(
            workID: work.id,
            field: field,
            heads: heads,
            leftID: heads[left].id,
            rightID: heads[right].id
        )
    }
}
