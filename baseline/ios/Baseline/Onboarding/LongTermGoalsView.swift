import SwiftUI

struct LongTermGoalsView: View {
    @EnvironmentObject private var onboarding: OnboardingViewModel

    private static let categories = ["Work", "Health", "Learning", "Creative", "Finance", "Personal"]

    @State private var goals: [LongTermGoalDraft] = [LongTermGoalDraft()]

    private var nonEmptyGoals: [LongTermGoalDraft] {
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
                            goals.append(LongTermGoalDraft())
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
                        onboarding.saveLongTermGoals(nonEmptyGoals.map { $0.forPersistence() })
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
        let goalText = goals[index].text.trimmingCharacters(in: .whitespacesAndNewlines)
        let showOptionalFields = goalText.count >= 3

        return VStack(alignment: .leading, spacing: 8) {
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

            if showOptionalFields {
                optionalFields(index: index)
            }
        }
    }

    @ViewBuilder
    private func optionalFields(index: Int) -> some View {
        if goals[index].showTargetDate {
            VStack(alignment: .leading, spacing: 4) {
                Text("By when? (optional)")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.textMuted)
                DatePicker(
                    "",
                    selection: Binding(
                        get: { goals[index].targetDate ?? Self.defaultTargetDate },
                        set: { newValue in
                            var next = goals
                            next[index].targetDate = newValue
                            goals = next
                        },
                    ),
                    displayedComponents: .date,
                )
                .datePickerStyle(.compact)
                .labelsHidden()
                .tint(Theme.Colors.accent)
            }
        } else {
            optionalAddChip(title: "Add target date +") {
                var next = goals
                next[index].showTargetDate = true
                if next[index].targetDate == nil {
                    next[index].targetDate = Self.defaultTargetDate
                }
                goals = next
            }
        }

        if goals[index].showBaseline {
            VStack(alignment: .leading, spacing: 4) {
                Text("Current baseline (optional)")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.textMuted)
                TextField(
                    "e.g. I currently bench 145lbs",
                    text: Binding(
                        get: { goals[index].currentBaseline },
                        set: { newValue in
                            var next = goals
                            next[index].currentBaseline = newValue
                            goals = next
                        },
                    ),
                )
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .padding(10)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                )
            }
        } else {
            optionalAddChip(title: "Add baseline +") {
                var next = goals
                next[index].showBaseline = true
                goals = next
            }
        }
    }

    private func optionalAddChip(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.textMuted)
                .padding(.vertical, 5)
                .padding(.horizontal, 10)
                .background(
                    Capsule()
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3])),
                )
        }
        .buttonStyle(.plain)
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

    private static var defaultTargetDate: Date {
        Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
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
