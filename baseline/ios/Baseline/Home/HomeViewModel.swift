import Combine
import Foundation
import SwiftUI

/// Today's goal row for the home list (will map from Supabase `goals` later).
struct HomeGoalItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let isNonNegotiable: Bool
    let isCompleted: Bool
}

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoading = false

    @Published var streakCurrent: Int = 0
    @Published var streakMax: Int = 0
    @Published var streakActive: Bool = false

    @Published var goalsCompleted: Int = 0
    @Published var goalsTotal: Int = 0
    /// `days.status` value when loaded from API; mock uses `in_progress`.
    @Published var dayStatus: String = "in_progress"

    @Published var goals: [HomeGoalItem] = []

    /// From `days.tomorrow_intention` when present.
    @Published var tomorrowIntention: String?

    private static let stableGoalIds: [UUID] = (1 ... 5).map { i in
        UUID(uuidString: String(format: "00000000-0000-4000-8000-%012x", i))!
    }

    private static let dayFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "EEEE, MMM d"
        f.locale = Locale.autoupdatingCurrent
        return f
    }()

    var formattedToday: String {
        Self.dayFormatter.string(from: Date())
    }

    var dayStatusLabel: String {
        switch dayStatus {
        case "in_progress": "In progress"
        case "strong", "solid", "light", "rest", "skipped":
            return dayStatus.capitalized
        default:
            return dayStatus.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    init() {
        applyMockSnapshot()
    }

    func refresh() async {
        isLoading = true
        try? await Task.sleep(nanoseconds: 400_000_000)
        applyMockSnapshot()
        isLoading = false
    }

    private func applyMockSnapshot() {
        streakCurrent = 7
        streakMax = 12
        streakActive = true
        dayStatus = "in_progress"
        tomorrowIntention = "Block 90 minutes for writing before noon."

        goals = [
            HomeGoalItem(
                id: Self.stableGoalIds[0],
                title: "Morning movement",
                isNonNegotiable: true,
                isCompleted: true,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[1],
                title: "Deep work — project brief",
                isNonNegotiable: true,
                isCompleted: false,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[2],
                title: "Reply to two priority emails",
                isNonNegotiable: false,
                isCompleted: true,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[3],
                title: "Walk at lunch",
                isNonNegotiable: false,
                isCompleted: false,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[4],
                title: "Plan tomorrow in Baseline",
                isNonNegotiable: false,
                isCompleted: false,
            ),
        ].sorted { a, b in
            if a.isNonNegotiable != b.isNonNegotiable { return a.isNonNegotiable && !b.isNonNegotiable }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }

        goalsTotal = goals.count
        goalsCompleted = goals.filter(\.isCompleted).count
    }
}
