import Foundation

/// Role: MendMark. True tap on a swapped Head. Rights both openings and folds Spooned to Mended.
struct MendMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var field: LineField
    var headID: UUID
    var seat: Int
    var opening: String
    var daykey: Int
}
