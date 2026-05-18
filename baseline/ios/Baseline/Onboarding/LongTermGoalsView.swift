import SwiftUI

private struct GoalEntry: Identifiable {
    let id: UUID
    var text: String
    var category: String
}

struct LongTermGoalsView: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel

    private static let categories = ["Work", "Health", "Learning", "Creative", "Finance", "Personal"]

    @State private var goals: [GoalEntry] = [GoalEntry(id: UUID(), text: "", category: "Work")]

    private var nonEmptyGoals: [GoalEntry] {
        goals.filter { !$0.text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    private var canContinue: Bool {
        !nonEmptyGoals.isEmpty
    }

    var body: some View {
        ZStack {
            Theme.Colors.background.ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    OnboardingProgressBarView(currentStep: 4, totalSteps: 5, showTimeEstimate: false)

                    Text("LONG TERM GOALS")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#3A2A55"))
                        .tracking(1.4)
                        .textCase(.uppercase)
                        .padding(.top, 10)

                    Text("What are you working toward?")
                        .font(.system(size: 22, weight: .light, design: .serif))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(.top, 8)

                    Text("The coach uses these to suggest daily actions. Be specific — not 'be healthier' but 'run 3x a week'.")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .lineSpacing(6)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 8)

                    VStack(spacing: 12) {
                        ForEach(Array(goals.enumerated()), id: \.element.id) { index, _ in
                            goalRow(index: index)
                        }
                    }
                    .padding(.top, 16)

                    if goals.count < 3 {
                        Button {
                            goals.append(GoalEntry(id: UUID(), text: "", category: "Work"))
                        } label: {
                            Text("Add another goal")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.textMuted)
                                .frame(maxWidth: .infinity)
                                .padding(10)
                                .background(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4])),
                                )
                        }
                        .buttonStyle(.plain)
                        .padding(.top, 4)
                    }

                    Spacer(minLength: 32)

                    BaselineButton(title: "Continue →") {
                        let pairs = nonEmptyGoals.map { (text: $0.text, category: $0.category) }
                        onboarding.saveLongTermGoals(pairs)
                        onboarding.goNext()
                    }
                    .opacity(canContinue ? 1 : 0.4)
                    .disabled(!canContinue)

                    Button("Skip for now") {
                        onboarding.saveLongTermGoals([])
                        onboarding.goNext()
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .padding(.top, 8)
                }
                .padding(.horizontal, Theme.Spacing.md)
                .padding(.top, Theme.Spacing.sm)
                .padding(.bottom, Theme.Spacing.xl)
            }
        }
    }

    private func goalRow(index: Int) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                TextField(
                    "e.g. Launch my app by September",
                    text: Binding(
                        get: { goals[index].text },
                        set: { newValue in
                            var next = goals
                            next[index].text = newValue
                            goals = next
                        },
                    ),
                )
                .font(.system(size: 14))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(12)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                )

                if goals.count > 1 {
                    Button {
                        goals.remove(at: index)
                    } label: {
                        Text("×")
                            .font(.system(size: 18, weight: .light))
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("Remove goal")
                }
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Self.categories, id: \.self) { cat in
                        chipButton(index: index, category: cat, selected: goals[index].category == cat)
                    }
                }
            }
        }
    }

    private func chipButton(index: Int, category: String, selected: Bool) -> some View {
        Button {
            var next = goals
            next[index].category = category
            goals = next
        } label: {
            Text(category)
                .font(.system(size: 11))
                .foregroundStyle(selected ? Color.white : Color(hex: "#666666"))
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .background(selected ? Color(hex: "#1A1228") : Color(hex: "#0F0F0F"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(selected ? Theme.Colors.accent : Color(hex: "#252525"), lineWidth: 1),
                )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress bar (onboarding)

private struct OnboardingProgressBarView: View {
    let currentStep: Int
    let totalSteps: Int
    let showTimeEstimate: Bool

    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(1 ... totalSteps, id: \.self) { step in
                    Capsule()
                        .fill(segmentColor(step: step))
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                }
            }
            Text(stepLabel)
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }

    private func segmentColor(step: Int) -> Color {
        if step < currentStep {
            return Theme.Colors.accent
        }
        if step == currentStep {
            return Theme.Colors.accent.opacity(0.5)
        }
        return Color(hex: "#252525")
    }

    private var stepLabel: String {
        if showTimeEstimate {
            return "Step \(currentStep) of \(totalSteps) · ~2 min"
        }
        return "Step \(currentStep) of \(totalSteps)"
    }
}
