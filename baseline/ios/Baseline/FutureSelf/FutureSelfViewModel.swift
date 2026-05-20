import Combine
import Foundation
import SwiftUI

@MainActor
final class FutureSelfViewModel: ObservableObject {
    @AppStorage("baseline.futureSelfMessage") var savedMessage: String = ""
    @AppStorage("baseline.futureSelfDate") var savedDateInterval: Double = 0
    @Published var draftMessage: String = ""
    @Published var isSaved: Bool = false
    @Published var isEditing: Bool = false

    var hasSavedMessage: Bool {
        !savedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var savedDateFormatted: String {
        guard savedDateInterval > 0 else { return "" }
        let date = Date(timeIntervalSince1970: savedDateInterval)
        return "Written on \(Self.dateOnlyFormatter.string(from: date))"
    }

    var wordCount: Int {
        draftMessage
            .split { $0.isWhitespace || $0.isNewline }
            .filter { !$0.isEmpty }
            .count
    }

    func startEditing() {
        draftMessage = savedMessage
        isEditing = true
    }

    func saveMessage() {
        let trimmed = draftMessage.trimmingCharacters(in: .whitespacesAndNewlines)
        savedMessage = trimmed
        draftMessage = trimmed
        savedDateInterval = Date().timeIntervalSince1970
        isEditing = false
        withAnimation(.easeOut(duration: 0.25)) {
            isSaved = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await MainActor.run {
                withAnimation(.easeOut(duration: 0.25)) {
                    isSaved = false
                }
            }
        }
    }

    func discardChanges() {
        draftMessage = savedMessage
        isEditing = false
    }

    func onAppear() {
        if !savedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            draftMessage = savedMessage
        }
        isEditing = savedMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static let dateOnlyFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
}
