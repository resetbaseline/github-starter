import SwiftUI

struct ReflectionView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel

    private var hasChipSelection: Bool {
        viewModel.selectedChips.values.contains { !$0.isEmpty }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ProgressBarView(currentStep: 2, totalSteps: 3, showTimeEstimate: false)

                ForEach(viewModel.selectedQuestions) { question in
                    questionBlock(question)
                }

                if hasChipSelection {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("COACH SEES")
                            .font(.system(size: 8))
                            .foregroundStyle(Color(hex: "#4A3880"))
                            .tracking(1.2)
                            .textCase(.uppercase)
                        Text(viewModel.aiSuggestionText)
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "#9B7FD4"))
                            .lineSpacing(3)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(.vertical, 7)
                    .padding(.horizontal, 9)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(hex: "#0F0828"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                    )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Anything else to add")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.textMuted)
                    TextField("", text: $viewModel.openEndedText, axis: .vertical)
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

                VStack(alignment: .leading, spacing: 6) {
                    Text("Tomorrow's intention (optional)")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.textMuted)
                    TextField("", text: $viewModel.tomorrowIntention, axis: .vertical)
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

                BaselineButton(title: "Finish check-in →") {
                    viewModel.submitReflectionAndShowResult()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.Colors.background)
    }

    private func questionBlock(_ question: ReflectionQuestion) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(question.text)
                .font(.system(size: 12, weight: .regular, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            chipLayout(for: question)
        }
    }

    @ViewBuilder
    private func chipLayout(for question: ReflectionQuestion) -> some View {
        let selected = viewModel.selectedChips[question.id, default: []]
        if question.chips.count > 2 {
            LazyVGrid(
                columns: [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)],
                alignment: .leading,
                spacing: 8,
            ) {
                ForEach(question.chips, id: \.self) { chip in
                    chipButton(question: question, chip: chip, selected: selected)
                }
            }
        } else {
            HStack(spacing: 8) {
                ForEach(question.chips, id: \.self) { chip in
                    chipButton(question: question, chip: chip, selected: selected)
                }
            }
        }
    }

    private func chipButton(question: ReflectionQuestion, chip: String, selected: Set<String>) -> some View {
        let isOn = selected.contains(chip)
        return Button {
            viewModel.toggleChip(questionId: question.id, chip: chip)
        } label: {
            Text(chip)
                .font(.system(size: 9))
                .foregroundStyle(isOn ? Color.white : Theme.Colors.textPrimary)
                .padding(.vertical, 4)
                .padding(.horizontal, 9)
                .frame(maxWidth: .infinity, alignment: .center)
                .background(isOn ? Color(hex: "#1A1228") : Color(hex: "#0F0F0F"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(isOn ? Theme.Colors.accent : Color(hex: "#252525"), lineWidth: 1),
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
