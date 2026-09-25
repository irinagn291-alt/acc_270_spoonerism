import Foundation

/// Role: Head. One seated word on the Line. The opening can be worn from a partner; the seat never moves.
struct Head: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var seat: Int
    var prefix: String
    var nativeOpening: String
    var wornOpening: String
    var stem: String
    var isRighted: Bool
    var isGrey: Bool

    var spoken: String {
        prefix + wornOpening + stem
    }

    var keepsNativeOpening: Bool {
        wornOpening.lowercased() == nativeOpening.lowercased()
    }
}

/// Role: Head. Opening cut of a seated word. Unlike openings are first letters, folded.
enum HeadCut: Sendable {
    struct Piece: Equatable, Sendable {
        var prefix: String
        var opening: String
        var stem: String
    }

    static func pieces(in text: String) -> [Piece] {
        text.split(whereSeparator: \.isWhitespace)
            .map { cut(String($0)) }
            .filter { !$0.opening.isEmpty }
    }

    static func qualifies(_ text: String) -> Bool {
        distinctSeats(in: pieces(in: text)).count >= 2
    }

    static func distinctSeats(in pieces: [Piece]) -> [Int] {
        var seen = Set<String>()
        var seats: [Int] = []
        for (offset, piece) in pieces.enumerated() {
            let key = piece.opening.lowercased()
            if seen.insert(key).inserted {
                seats.append(offset)
            }
        }
        return seats
    }

    static func cut(_ word: String) -> Piece {
        guard let index = word.firstIndex(where: { $0.isLetter }) else {
            return Piece(prefix: "", opening: "", stem: word)
        }
        let after = word.index(after: index)
        return Piece(
            prefix: String(word[..<index]),
            opening: String(word[index]),
            stem: String(word[after...])
        )
    }

    static func fieldText(_ work: Work, _ field: LineField) -> String {
        switch field {
        case .artist:
            return work.artist
        case .title:
            return work.title
        }
    }
}
