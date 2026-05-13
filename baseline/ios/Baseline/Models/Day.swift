import Foundation

struct Day: Identifiable, Codable, Hashable {
    var id: UUID
    var userId: UUID
    var date: String
    var status: String
    var goalsCount: Int
    var goalsCompleted: Int

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case date
        case status
        case goalsCount = "goals_count"
        case goalsCompleted = "goals_completed"
    }
}
