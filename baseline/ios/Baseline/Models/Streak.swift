import Foundation

struct Streak: Codable, Hashable {
    var currentCount: Int
    var maxCount: Int
    var active: Bool

    enum CodingKeys: String, CodingKey {
        case currentCount = "current_count"
        case maxCount = "max_count"
        case active
    }
}
