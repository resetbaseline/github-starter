import Foundation

struct GoalClassificationResponse: Codable {
    let classifications: [String: GoalClassification]
}

struct GoalClassification: Codable, Equatable {
    let type: String
    let extractedDate: String?
}
