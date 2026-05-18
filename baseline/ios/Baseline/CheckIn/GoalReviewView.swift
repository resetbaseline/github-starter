import SwiftUI

struct GoalReviewView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProgressBarView(currentStep: 1, totalSteps: 3, showTimeEstimate: true)

                VStack(alignment: .leading, spacing: 4) {
                    Text(greetingLine + ".")
                        .font(.system(size: 16, weight: .light, design: .serif))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Tap each goal you finished today.")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.textMuted)
                }

                HStack {
                    Text("FOCUS LOGGED")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.textMuted)
                        .tracking(1.2)
                        .textCase(.uppercase)
                    Spacer(minLength: 0)
                    Text("\(viewModel.focusMinutesTotal) min")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.accent)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 10)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                )

                VStack(spacing: 0) {
                    ForEach(viewModel.goals) { goal in
                        Button {
                            viewModel.toggleGoal(id: goal.id)
                        } label: {
                            goalRow(goal)
                        }
                        .buttonStyle(.plain)
                        if goal.id != viewModel.goals.last?.id {
                            Divider()
                                .background(Color(hex: "#111111"))
                        }
                    }
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 10)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 9, style: .continuous)
                        .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                )

                BaselineButton(title: "Continue →") {
                    viewModel.goToReflection()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.Colors.background)
    }

    private func goalRow(_ goal: CheckInGoalRow) -> some View {
        HStack(alignment: .center, spacing: 7) {
            if goal.isNonNegotiable {
                Rectangle()
                    .fill(Color(hex: "#1E1030"))
                    .frame(width: 2)
            }
            checkbox(done: goal.completed)
            Text(goal.title)
                .font(.system(size: 10))
                .foregroundStyle(goal.completed ? Color(hex: "#333333") : Theme.Colors.textPrimary)
                .strikethrough(goal.completed, color: Color(hex: "#333333"))
                .frame(maxWidth: .infinity, alignment: .leading)
            if goal.isNonNegotiable {
                Image(systemName: "pin.fill")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#1E1030"))
            }
        }
        .padding(.vertical, 5)
    }

    private func checkbox(done: Bool) -> some View {
        Group {
            if done {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 14, height: 14)
                    Image(systemName: "checkmark")
                        .font(.system(size: 7, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .strokeBorder(Color(hex: "#222222"), lineWidth: 1.5)
                    .frame(width: 14, height: 14)
            }
        }
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let prefix: String
        switch hour {
        case 0 ..< 12: prefix = "Good morning"
        case 12 ..< 17: prefix = "Good afternoon"
        default: prefix = "Good evening"
        }
        if let name = auth.onboardingPreferredName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return "\(prefix), \(name)"
        }
        return prefix
    }
}

// MARK: - Progress

private struct ProgressBarView: View {
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
