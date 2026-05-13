import Foundation

struct User: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String?
    var timezone: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case timezone
    }
}
