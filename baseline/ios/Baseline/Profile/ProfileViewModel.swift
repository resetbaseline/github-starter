import Combine
import Foundation
import SwiftUI

enum DayState: Equatable {
    case strong
    case solid
    case light
    case skipped
    case freeze
    case future
    case empty
}

struct SelectedDay: Identifiable, Equatable {
    let id = UUID()
    let day: Int
    let month: Int
    let year: Int
    let state: DayState
}

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var streakCurrent: Int = 7
    @Published var streakMax: Int = 12
    @Published var totalFocusMinutes: Int = 340
    @Published var totalGoalsCompleted: Int = 47
    @Published var totalCheckIns: Int = 14
    @Published var memberSince: Date = Calendar.current.date(byAdding: .day, value: -14, to: Date()) ?? Date()

    @AppStorage("baseline.freezesRemaining") var freezesRemaining: Int = 2
    @Published var calendarData: [String: [Int: DayState]] = [:]
    @Published var selectedDay: SelectedDay?

    var streakTagline: String { "Your baseline is holding." }

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

    init() {
        calendarData = Self.mockCalendarData()
    }

    func applyFreeze(day: Int, month: Int, year: Int) {
        let key = Self.monthKey(year: year, month: month)
        var monthData = calendarData[key] ?? [:]
        monthData[day] = .freeze
        calendarData[key] = monthData
        freezesRemaining = max(0, freezesRemaining - 1)
        if selectedDay?.day == day, selectedDay?.month == month, selectedDay?.year == year {
            selectedDay = SelectedDay(day: day, month: month, year: year, state: .freeze)
        }
    }

    static func monthKey(year: Int, month: Int) -> String {
        "\(year)-\(month)"
    }

    private static let memberSinceFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    private static func mockCalendarData() -> [String: [Int: DayState]] {
        var may: [Int: DayState] = [
            1: .strong, 2: .strong, 3: .solid, 4: .strong, 5: .strong, 6: .strong, 7: .solid,
            8: .strong, 9: .freeze, 10: .strong, 11: .strong, 12: .strong, 13: .solid, 14: .strong,
            15: .strong, 16: .strong, 17: .light, 18: .strong, 19: .strong, 20: .strong,
            21: .strong, 22: .strong,
        ]
        for day in 23 ... 31 {
            may[day] = .future
        }

        let april: [Int: DayState] = [
            1: .strong, 2: .strong, 3: .strong, 4: .solid, 5: .strong, 6: .strong, 7: .strong,
            8: .solid, 9: .strong, 10: .strong, 11: .strong, 12: .strong, 13: .light, 14: .strong,
            15: .strong, 16: .strong, 17: .strong, 18: .strong, 19: .solid, 20: .strong,
            21: .strong, 22: .strong, 23: .strong, 24: .strong, 25: .strong, 26: .strong,
            27: .solid, 28: .strong, 29: .skipped, 30: .strong,
        ]

        let march: [Int: DayState] = [
            1: .strong, 2: .strong, 3: .solid, 4: .strong, 5: .strong, 6: .skipped, 7: .skipped,
            8: .strong, 9: .strong, 10: .strong, 11: .solid, 12: .strong, 13: .strong, 14: .strong,
            15: .strong, 16: .strong, 17: .solid, 18: .strong, 19: .strong, 20: .skipped,
            21: .strong, 22: .strong, 23: .strong, 24: .strong, 25: .strong, 26: .strong,
            27: .strong, 28: .strong, 29: .strong, 30: .strong, 31: .solid,
        ]

        return [
            "2026-5": may,
            "2026-4": april,
            "2026-3": march,
        ]
    }
}
