import Foundation

struct CheckIn: Identifiable, Codable, Hashable {
    var id: UUID
    var dayId: UUID
    var submittedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case dayId = "day_id"
        case submittedAt = "submitted_at"
    }
}
