import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var viewModel = HomeViewModel()
    @State private var showCoachAssist = false

    var body: some View {
        ZStack(alignment: .top) {
            Theme.Colors.background.ignoresSafeArea()

            VStack(spacing: 0) {
                topStrip
                    .padding(.horizontal, 18)
                    .padding(.top, 4)
                    .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 8) {
                        MountainProgressCard()
                        progressBarRow
                        NonNegotiablesSection(showCoachAssist: $showCoachAssist)
                        OtherGoalsSection()
                        focusSessionCard
                        checkInCard
                    }
                    .padding(.horizontal, 18)
                    .padding(.bottom, Theme.Spacing.lg)
                }
                .refreshable {
                    await viewModel.refresh()
                }
            }

            if viewModel.isLoading {
                ProgressView()
                    .tint(Theme.Colors.accent)
                    .padding(.top, 56)
            }
        }
        .environmentObject(viewModel)
        .sheet(isPresented: $showCoachAssist) {
            CoachAssistModal(
                isPresented: $showCoachAssist,
                longTermGoals: auth.longTermGoals,
                onAdd: { text, category in
                    viewModel.addNonNegotiable(text: text, category: category)
                },
            )
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.hidden)
        }
    }

    private var topStrip: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(greetingLine + ".")
                    .font(.system(size: 18, weight: .light))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Let's protect your day.")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            StreakPillView(count: viewModel.streakCurrent)
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

    private var progressBarRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text("\(viewModel.goalsCompleted) of \(viewModel.goalsTotal) goals completed")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .textCase(.uppercase)
                    .tracking(1.2)
                Spacer(minLength: 0)
                Text(viewModel.progressPercentString)
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Color(hex: "#181818"))
                        .frame(height: 2)
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(Theme.Colors.accent)
                        .frame(width: max(2, geo.size.width * viewModel.progressFraction), height: 2)
                }
            }
            .frame(height: 2)
        }
    }

    private var focusSessionCard: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .strokeBorder(Color(hex: "#2D1F4A"), style: StrokeStyle(lineWidth: 1.5, dash: [4, 4]))
                    .frame(width: 42, height: 42)
                Circle()
                    .fill(Color(hex: "#1A1228"))
                    .frame(width: 30, height: 30)
                Image(systemName: "play.fill")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Start Focus Session")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white)
                Text("Eliminate distractions. Build what matters.")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#444444"))
                HStack(spacing: 8) {
                    chip(icon: "clock", label: "25 min")
                    chip(icon: "nosign", label: "Apps blocked")
                    chip(icon: "bell", label: "Focus mode")
                }
                .padding(.top, 2)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#222222"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(Color(hex: "#0C0C0C"))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color(hex: "#161616"), lineWidth: 0.5),
        )
    }

    private func chip(icon: String, label: String) -> some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 8))
            Text(label)
                .font(.system(size: 8))
        }
        .foregroundStyle(Color(hex: "#333333"))
    }

    private var checkInCard: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#1A1228"))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#2D1F4A"), lineWidth: 0.5),
                    )
                Image(systemName: "message.circle")
                    .font(.system(size: 14))
                    .foregroundStyle(Theme.Colors.accent)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text("Check In")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(Color.white)
                Text("Reflect on your day and plan tomorrow.")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#444444"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(Color(hex: "#222222"))
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 12)
        .background(Color(hex: "#0C0C0C"))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(Color(hex: "#161616"), lineWidth: 0.5),
        )
    }
}

// MARK: - Mountain card

private struct MountainProgressCard: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("TODAY'S PROGRESS")
                    .font(.system(size: 11))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .textCase(.uppercase)
                    .tracking(2)
                Spacer(minLength: 0)
                Text("\(viewModel.goalsCompleted) of \(viewModel.goalsTotal) done")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.accent)
            }
            MountainProgressView(completed: viewModel.goalsCompleted, total: viewModel.goalsTotal)
                .frame(height: 70)
        }
        .padding(12)
        .background(Color(hex: "#0A0612"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#1A1030"), lineWidth: 0.5),
        )
    }
}

// MARK: - Goal sections

private struct NonNegotiablesSection: View {
    @EnvironmentObject private var viewModel: HomeViewModel
    @Binding var showCoachAssist: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY'S NON-NEGOTIABLES (\(viewModel.nonNegotiableGoals.count))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: "#333333"))
                    .tracking(1)
                Spacer(minLength: 0)
                Button("Edit") {}
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
                    .buttonStyle(.plain)
            }
            VStack(spacing: 0) {
                ForEach(Array(viewModel.nonNegotiableGoals.enumerated()), id: \.element.id) { index, goal in
                    nonNegotiableRow(goal)
                    if index < viewModel.nonNegotiableGoals.count - 1 {
                        Divider()
                            .background(Color(hex: "#0F0F0F"))
                    }
                }
                addNonNegotiableRow
            }
            .background(Color(hex: "#0C0C0C"))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color(hex: "#161616"), lineWidth: 0.5),
            )
        }
    }

    private var addNonNegotiableRow: some View {
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
        }
        .buttonStyle(.plain)
    }

    private func nonNegotiableRow(_ goal: HomeGoalItem) -> some View {
        HStack(alignment: .center, spacing: 0) {
            HStack(alignment: .center, spacing: 12) {
                checkbox(done: goal.isCompleted)
                VStack(alignment: .leading, spacing: 3) {
                    Text(goal.title)
                        .font(.system(size: 12))
                        .foregroundStyle(goal.isCompleted ? Color(hex: "#222222") : Theme.Colors.textPrimary)
                        .strikethrough(goal.isCompleted, color: Color(hex: "#222222"))
                    Text(goal.category)
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#3A3A3A"))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                Text(goal.timeLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#333333"))
                Image(systemName: "pin.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#2A1A45"))
            }
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .overlay(alignment: .leading) {
                Rectangle()
                    .fill(Color(hex: "#2A1A45"))
                    .frame(width: 2)
                    .padding(.vertical, 4)
            }
        }
    }

    private func checkbox(done: Bool) -> some View {
        Group {
            if done {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .strokeBorder(Color(hex: "#222222"), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            }
        }
    }
}

private struct OtherGoalsSection: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("OTHER GOALS (\(viewModel.otherGoals.count))")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(Color(hex: "#333333"))
                    .tracking(1)
                Spacer(minLength: 0)
                Button("Edit") {}
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
                    .buttonStyle(.plain)
            }
            VStack(spacing: 0) {
                ForEach(Array(viewModel.otherGoals.enumerated()), id: \.element.id) { index, goal in
                    otherGoalRow(goal)
                    if index < viewModel.otherGoals.count - 1 {
                        Divider()
                            .background(Color(hex: "#0F0F0F"))
                    }
                }
            }
            .background(Color(hex: "#0C0C0C"))
            .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 11, style: .continuous)
                    .stroke(Color(hex: "#161616"), lineWidth: 0.5),
            )
        }
    }

    private func otherGoalRow(_ goal: HomeGoalItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            checkbox(done: goal.isCompleted)
            VStack(alignment: .leading, spacing: 3) {
                Text(goal.title)
                    .font(.system(size: 12))
                    .foregroundStyle(goal.isCompleted ? Color(hex: "#222222") : Theme.Colors.textPrimary)
                    .strikethrough(goal.isCompleted, color: Color(hex: "#222222"))
                Text(goal.category)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#3A3A3A"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(goal.timeLabel)
                .font(.system(size: 9))
                .foregroundStyle(Color(hex: "#333333"))
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }

    private func checkbox(done: Bool) -> some View {
        Group {
            if done {
                ZStack {
                    Circle()
                        .fill(Theme.Colors.accent)
                        .frame(width: 18, height: 18)
                    Image(systemName: "checkmark")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundStyle(.white)
                }
            } else {
                Circle()
                    .strokeBorder(Color(hex: "#222222"), lineWidth: 1.5)
                    .frame(width: 18, height: 18)
            }
        }
    }
}
