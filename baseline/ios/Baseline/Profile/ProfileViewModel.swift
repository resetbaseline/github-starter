import Combine
import Foundation
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var streakCurrent: Int = 7
    @Published var streakMax: Int = 12
    @Published var totalFocusMinutes: Int = 340
    @Published var totalGoalsCompleted: Int = 47
    @Published var totalCheckIns: Int = 14
    @Published var memberSince: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()
    @Published var showResetConfirm: Bool = false

    var memberSinceFormatted: String {
        "Member since \(Self.memberSinceFormatter.string(from: memberSince))"
    }

    var totalFocusHours: String {
        let hours = totalFocusMinutes / 60
        let minutes = totalFocusMinutes % 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }

    var streakSummary: String {
        "Current: \(streakCurrent) days · Best: \(streakMax) days"
    }

    private static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
}
