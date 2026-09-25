import Foundation

/// Role: MuffMark. Miss on a Head that was not in the swapped pair. Greys that Head and keeps the Line. Reviewable on Saved.
struct MuffMark: Identifiable, Equatable, Sendable, Codable {
    var id: UUID
    var workID: UUID
    var field: LineField
    var headID: UUID
    var seat: Int
    var spoken: String
    var daykey: Int
}
