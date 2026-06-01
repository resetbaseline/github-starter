import Combine
import Foundation
import SwiftUI

/// Today's goal row for the home list (will map from Supabase `goals` later).
struct HomeGoalItem: Identifiable, Equatable {
    let id: UUID
    let title: String
    let category: String
    let timeLabel: String
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

    var nonNegotiableGoals: [HomeGoalItem] {
        goals.filter(\.isNonNegotiable)
    }

    var otherGoals: [HomeGoalItem] {
        goals.filter { !$0.isNonNegotiable }
    }

    var progressFraction: Double {
        Double(goalsCompleted) / Double(max(goalsTotal, 1))
    }

    var progressPercentString: String {
        "\(Int(progressFraction * 100))%"
    }

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

    func addNonNegotiable(text: String, category: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let item = HomeGoalItem(
            id: UUID(),
            title: trimmed,
            category: category,
            timeLabel: "—",
            isNonNegotiable: true,
            isCompleted: false,
        )
        goals.append(item)
        sortGoals()
        refreshGoalCounts()
    }

    func removeGoal(id: UUID) {
        goals.removeAll { $0.id == id }
        refreshGoalCounts()
    }

    /// Marks a non-negotiable (daily anchor) complete and records streak activity when authenticated.
    func completeAnchor(_ anchor: HomeGoalItem) {
        guard anchor.isNonNegotiable, !anchor.isCompleted else { return }
        guard let index = goals.firstIndex(where: { $0.id == anchor.id }) else { return }

        let item = goals[index]
        goals[index] = HomeGoalItem(
            id: item.id,
            title: item.title,
            category: item.category,
            timeLabel: item.timeLabel,
            isNonNegotiable: item.isNonNegotiable,
            isCompleted: true,
        )
        refreshGoalCounts()

        Task {
            await EdgeFunctionsService.processAnchorComplete(
                anchorId: anchor.id,
                anchorText: anchor.title,
            )
        }
    }

    private func sortGoals() {
        goals.sort { a, b in
            if a.isNonNegotiable != b.isNonNegotiable { return a.isNonNegotiable && !b.isNonNegotiable }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }
    }

    private func refreshGoalCounts() {
        goalsTotal = goals.count
        goalsCompleted = goals.filter(\.isCompleted).count
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
                category: "Wellness",
                timeLabel: "7:30 AM",
                isNonNegotiable: true,
                isCompleted: true,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[1],
                title: "Deep work — project brief",
                category: "Deep work",
                timeLabel: "10:00 AM",
                isNonNegotiable: true,
                isCompleted: false,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[2],
                title: "Reply to two priority emails",
                category: "Communication",
                timeLabel: "11:30 AM",
                isNonNegotiable: false,
                isCompleted: true,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[3],
                title: "Walk at lunch",
                category: "Movement",
                timeLabel: "12:30 PM",
                isNonNegotiable: false,
                isCompleted: false,
            ),
            HomeGoalItem(
                id: Self.stableGoalIds[4],
                title: "Plan tomorrow in Baseline",
                category: "Planning",
                timeLabel: "8:45 PM",
                isNonNegotiable: false,
                isCompleted: false,
            ),
        ].sorted { a, b in
            if a.isNonNegotiable != b.isNonNegotiable { return a.isNonNegotiable && !b.isNonNegotiable }
            return a.title.localizedCaseInsensitiveCompare(b.title) == .orderedAscending
        }

        refreshGoalCounts()
    }
}
