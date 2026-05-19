import SwiftUI

struct PlanTomorrowView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel
    @EnvironmentObject private var auth: AuthManager

    @State private var showCoachAssist = false
    @State private var isAddingOtherGoal = false
    @State private var otherGoalFieldText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ProgressBarView(currentStep: 3, totalSteps: 4, showTimeEstimate: false)

                nonNegotiablesSection
                otherGoalsSection
                intentionSection

                BaselineButton(title: "See today's result →") {
                    viewModel.finalizePlanAndShowResult()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.Colors.background)
        .sheet(isPresented: $showCoachAssist) {
            CoachAssistModal(
                isPresented: $showCoachAssist,
                longTermGoals: auth.longTermGoals,
                onAdd: { text, category in
                    viewModel.addCustomTomorrowGoal(text: text, category: category, isNonNegotiable: true)
                },
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var nonNegotiablesSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What must happen tomorrow?")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("The coach carried forward what you didn't finish today.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.textMuted)

            ForEach(viewModel.tomorrowNonNegotiables) { draft in
                tomorrowGoalCard(draft)
            }

            addNonNegotiableCoachAssistRow
        }
    }

    private var otherGoalsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Anything else on the list?")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text("Based on your long term goals.")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.textMuted)

            ForEach(viewModel.tomorrowOtherGoals) { draft in
                tomorrowGoalCard(draft)
            }

            dashedAddButton(title: "Add another goal") {
                isAddingOtherGoal.toggle()
                if !isAddingOtherGoal {
                    otherGoalFieldText = ""
                }
            }

            if isAddingOtherGoal {
                TextField("Type and press return", text: $otherGoalFieldText)
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .padding(7)
                    .background(Color(hex: "#0F0F0F"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                    )
                    .onSubmit {
                        viewModel.addCustomTomorrowGoal(text: otherGoalFieldText, isNonNegotiable: false)
                        otherGoalFieldText = ""
                    }
            }
        }
    }

    private var intentionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("What's your intention for tomorrow?")
                .font(.system(size: 16, weight: .light, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)

            Button {
                viewModel.tomorrowIntention = viewModel.suggestedIntentionText
            } label: {
                Text(viewModel.suggestedIntentionText)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
                    .padding(.vertical, 5)
                    .padding(.horizontal, 12)
                    .background(Color(hex: "#0F0828"))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                    )
            }
            .buttonStyle(.plain)

            TextField(
                "",
                text: $viewModel.tomorrowIntention,
                prompt: Text("Or write your own...")
                    .font(.system(size: 13))
                    .foregroundStyle(Theme.Colors.textMuted),
                axis: .vertical,
            )
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1 ... 3)
                .padding(7)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                )
        }
    }

    private func tomorrowGoalCard(_ draft: TomorrowGoalDraft) -> some View {
        ZStack(alignment: .topTrailing) {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(draft.text)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .fixedSize(horizontal: false, vertical: true)
                    Text(draft.category)
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#3A3A3A"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                if draft.isSuggested {
                    suggestionAcceptButton(for: draft)
                } else {
                    Button {
                        viewModel.removeTomorrowGoal(id: draft.id)
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Theme.Colors.textMuted)
                            .frame(width: 28, height: 28)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(EdgeInsets(top: draft.isSuggested ? 22 : 10, leading: 12, bottom: 10, trailing: 12))

            if draft.isSuggested {
                Text("Suggested")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color(hex: "#0F0828"))
                    .clipShape(Capsule())
                    .overlay(
                        Capsule()
                            .stroke(Color(hex: "#1A1030"), lineWidth: 1),
                    )
                    .padding(.top, 6)
                    .padding(.trailing, 8)
            }
        }
        .background(Color(hex: "#0F0F0F"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
        )
    }

    @ViewBuilder
    private func suggestionAcceptButton(for draft: TomorrowGoalDraft) -> some View {
        Button {
            viewModel.acceptSuggestion(id: draft.id)
        } label: {
            if draft.isAccepted {
                Circle()
                    .fill(Theme.Colors.accent)
                    .frame(width: 28, height: 28)
                    .overlay(
                        Image(systemName: "checkmark")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Color.white),
                    )
            } else {
                Circle()
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .frame(width: 28, height: 28)
            }
        }
        .buttonStyle(.plain)
    }

    private var addNonNegotiableCoachAssistRow: some View {
        Button {
            showCoachAssist = true
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .strokeBorder(Color(hex: "#2A2A2A"), style: StrokeStyle(lineWidth: 1, dash: [3, 2]))
                        .frame(width: 14, height: 14)
                    Image(systemName: "plus")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundStyle(Color(hex: "#444444"))
                }
                Text("Add non-negotiable")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#444444"))
                Spacer(minLength: 0)
            }
            .padding(EdgeInsets(top: 5, leading: 9, bottom: 5, trailing: 9))
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 4])),
            )
        }
        .buttonStyle(.plain)
    }

    private func dashedAddButton(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
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
