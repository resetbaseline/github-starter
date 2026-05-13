import Foundation

struct Goal: Identifiable, Codable, Hashable {
    var id: UUID
    var dayId: UUID
    var text: String
    var status: String

    enum CodingKeys: String, CodingKey {
        case id
        case dayId = "day_id"
        case text
        case status
    }
}
