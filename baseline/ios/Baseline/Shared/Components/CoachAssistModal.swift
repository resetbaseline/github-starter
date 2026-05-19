import SwiftUI

struct CoachAssistModal: View {
    @Binding var isPresented: Bool
    let longTermGoals: [(text: String, category: String)]
    let onAdd: (String, String) -> Void

    @State private var inputText = ""
    @State private var suggestion = ""
    @State private var suggestionWhy = ""
    @State private var matchedGoal = ""
    @State private var matchedCategory = ""

    private var canCoach: Bool {
        !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        VStack(spacing: 0) {
            handleBar
                .padding(.top, 10)
                .padding(.bottom, 14)

            VStack(alignment: .leading, spacing: 0) {
                header
                    .padding(.bottom, 12)

                inputRow
                    .padding(.bottom, 10)

                if !suggestion.isEmpty {
                    suggestionCard
                        .padding(.bottom, 10)
                }
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 20)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: "#0F0F0F"))
        .clipShape(
            UnevenRoundedRectangle(
                topLeadingRadius: 20,
                bottomLeadingRadius: 0,
                bottomTrailingRadius: 0,
                topTrailingRadius: 20,
                style: .continuous,
            ),
        )
    }

    private var handleBar: some View {
        RoundedRectangle(cornerRadius: 1.5, style: .continuous)
            .fill(Color(hex: "#2A2A2A"))
            .frame(width: 28, height: 3)
            .frame(maxWidth: .infinity)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#1A1228"))
                    .frame(width: 26, height: 26)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                    )
                Image(systemName: "sparkles")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.accent)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("Coach assist")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.white)
                Text("Turning your idea into a daily action")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#555555"))
            }

            Spacer(minLength: 0)
        }
    }

    private var inputRow: some View {
        HStack(spacing: 8) {
            TextField(
                "",
                text: $inputText,
                prompt: Text("Describe something abstract...")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textMuted),
            )
            .font(.system(size: 11))
            .foregroundStyle(Theme.Colors.textPrimary)

            Button {
                generateSuggestion()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 8))
                    Text("Coach")
                        .font(.system(size: 8))
                }
                .foregroundStyle(Theme.Colors.accent)
                .padding(.vertical, 3)
                .padding(.horizontal, 7)
                .background(Color(hex: "#0A0614"))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                )
            }
            .buttonStyle(.plain)
            .disabled(!canCoach)
            .opacity(canCoach ? 1 : 0.5)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 10)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
        )
    }

    private var suggestionCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("SUGGESTED DAILY ACTION")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#4A3880"))
                .tracking(1.2)
                .textCase(.uppercase)

            Text(suggestion)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color.white)
                .fixedSize(horizontal: false, vertical: true)

            Text(suggestionWhy)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#555555"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)

            if !matchedGoal.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 8))
                    Text("Towards: \(matchedGoal)")
                        .font(.system(size: 8))
                }
                .foregroundStyle(Color(hex: "#3A2A55"))
                .padding(.vertical, 2)
                .padding(.horizontal, 6)
                .background(Color(hex: "#0A0614"))
                .clipShape(RoundedRectangle(cornerRadius: 3, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .stroke(Color(hex: "#1A1030"), lineWidth: 1),
                )
            }

            HStack(spacing: 8) {
                Button {
                    onAdd(suggestion, matchedCategory)
                    dismissAndReset()
                } label: {
                    Text("Add as non-negotiable")
                        .font(.system(size: 10))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(9)
                        .background(Theme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    inputText = suggestion
                } label: {
                    Text("Edit")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#888888"))
                        .padding(9)
                        .padding(.horizontal, 3)
                        .background(Color(hex: "#111111"))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                        )
                }
                .buttonStyle(.plain)

                Button {
                    dismissAndReset()
                } label: {
                    Text("✕")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#333333"))
                        .padding(.vertical, 9)
                        .padding(.horizontal, 5)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .background(Color(hex: "#060410"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
        )
    }

    private func generateSuggestion() {
        let raw = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return }
        let lower = raw.lowercased()

        if lower.contains("guitar") || lower.contains("music") || lower.contains("instrument") {
            suggestion = "Learn 3 chords: E, G, and A"
            suggestionWhy = "Specific enough to complete in one session. These three chords unlock hundreds of songs."
            matchedCategory = "Creative"
        } else if lower.contains("run") || lower.contains("gym") || lower.contains("workout") || lower.contains("exercise") {
            suggestion = "Complete one 30-minute workout session"
            suggestionWhy = "Consistent daily sessions build the habit faster than longer irregular ones."
            matchedCategory = "Health"
        } else if lower.contains("read") || lower.contains("book") || lower.contains("pages") {
            suggestion = "Read 20 pages"
            suggestionWhy = "20 pages daily compounds to 12+ books a year."
            matchedCategory = "Learning"
        } else if lower.contains("write") || lower.contains("writing") || lower.contains("essay") || lower.contains("thesis") {
            suggestion = "Write 300 words — no editing allowed"
            suggestionWhy = "Volume before quality. 300 words gets the session started."
            matchedCategory = "Creative"
        } else if lower.contains("code") || lower.contains("build") || lower.contains("app") || lower.contains("feature") {
            suggestion = "Ship one small feature or fix one bug"
            suggestionWhy = "Consistent small progress beats sporadic big sessions."
            matchedCategory = "Work"
        } else if lower.contains("meditat") || lower.contains("breath") || lower.contains("mindful") {
            suggestion = "10-minute morning meditation before your phone"
            suggestionWhy = "Before-phone timing is the highest-leverage moment for this habit."
            matchedCategory = "Health"
        } else if lower.contains("study") || lower.contains("learn") || lower.contains("course") {
            suggestion = "Complete one focused study session — 25 minutes, no distractions"
            suggestionWhy = "Pomodoro-length sessions match your focus block setup in Baseline."
            matchedCategory = "Learning"
        } else {
            suggestion = "Complete one focused session on: \(raw)"
            suggestionWhy = "Breaking it into one daily session keeps it achievable."
            matchedCategory = "Work"
        }

        resolveMatchedLongTermGoal(from: raw)
    }

    private func resolveMatchedLongTermGoal(from input: String) {
        let lower = input.lowercased()
        let keywords = lower
            .split { !$0.isLetter && !$0.isNumber }
            .map(String.init)
            .filter { $0.count > 2 }

        for goal in longTermGoals {
            let goalLower = goal.text.lowercased()
            let keywordHit = keywords.contains { goalLower.contains($0) }
            let containsInput = goalLower.contains(lower) || lower.contains(goalLower)
            if keywordHit || containsInput {
                matchedGoal = goal.text
                return
            }
        }

        if let first = longTermGoals.first {
            matchedGoal = first.text
        } else {
            matchedGoal = ""
        }
    }

    private func dismissAndReset() {
        isPresented = false
        resetState()
    }

    private func resetState() {
        inputText = ""
        suggestion = ""
        suggestionWhy = ""
        matchedGoal = ""
        matchedCategory = ""
    }
}
