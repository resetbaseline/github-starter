import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var viewModel = ProfileViewModel()

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    private static let targetDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d, yyyy"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        identityCard
                        streakCard
                        longTermGoalsCard
                        settingsSection
                        dangerZone
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Theme.Colors.background)
        .confirmationDialog(
            "This will delete all local data. Are you sure?",
            isPresented: $viewModel.showResetConfirm,
            titleVisibility: .visible,
        ) {
            Button("Reset", role: .destructive) {}
            Button("Cancel", role: .cancel) {}
        }
    }

    private var header: some View {
        Text("Profile")
            .font(.system(size: 17, weight: .light))
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(Theme.Colors.background)
    }

    private var identityCard: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center, spacing: 14) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "#1A1228"))
                        .frame(width: 52, height: 52)
                        .overlay(
                            Circle()
                                .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                        )
                    Text(userInitials)
                        .font(.system(size: 20, weight: .light))
                        .foregroundStyle(Theme.Colors.accent)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(displayName)
                        .font(.system(size: 16, weight: .light))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text(viewModel.memberSinceFormatted)
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            Rectangle()
                .fill(Color(hex: "#1A1030"))
                .frame(height: 1)

            HStack(spacing: 0) {
                statColumn(value: "\(viewModel.totalGoalsCompleted)", label: "Goals")
                statColumn(value: viewModel.totalFocusHours, label: "Focus")
                statColumn(value: "\(viewModel.totalCheckIns)", label: "Check-ins")
            }
        }
        .padding(16)
        .background(Color(hex: "#0A0612"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#1A1030"), lineWidth: 1),
        )
    }

    private func statColumn(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#444444"))
                .tracking(1.2)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    private var streakCard: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 4) {
                Text("STREAK")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .tracking(1.2)
                    .textCase(.uppercase)
                Text("\(viewModel.streakCurrent)")
                    .font(.system(size: 36, weight: .ultraLight))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("days")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#555555"))
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 4) {
                Text("Best")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#555555"))
                Text("\(viewModel.streakMax) days")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Theme.Colors.textPrimary)
                if viewModel.streakCurrent >= viewModel.streakMax {
                    Text("Keep going")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }
        }
        .padding(14)
        .background(Color(hex: "#0A0612"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#1A1030"), lineWidth: 1),
        )
    }

    private var longTermGoalsCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LONG TERM GOALS")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .tracking(1.2)
                    .textCase(.uppercase)
                Spacer(minLength: 0)
                Button("Edit") {}
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
                    .buttonStyle(.plain)
            }

            if auth.longTermGoalDrafts.isEmpty {
                Text("No long term goals set yet.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.textMuted)
                Button("Add goals") {}
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.accent)
                    .buttonStyle(.plain)
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    ForEach(auth.longTermGoalDrafts, id: \.id) { goal in
                        longTermGoalRow(goal)
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(hex: "#0C0C0C"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#161616"), lineWidth: 1),
        )
    }

    private func longTermGoalRow(_ goal: LongTermGoalDraft) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(goal.text)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            HStack(spacing: 6) {
                goalChip(goal.category)
                if let targetDate = goal.targetDate {
                    goalChip("By \(Self.targetDateFormatter.string(from: targetDate))")
                }
            }

            if !goal.currentBaseline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                Text(goal.currentBaseline)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .padding(.top, 2)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private func goalChip(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 8))
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

    private var settingsSection: some View {
        VStack(spacing: 0) {
            settingRow(label: "Wake time", value: formattedWakeTime, showsChevron: false)
            settingRow(label: "Check-in time", value: formattedCheckInTime, showsChevron: false)
            settingRow(label: "Notifications", value: "On", valueColor: Theme.Colors.accent, showsChevron: true)
            settingRow(
                label: "App version",
                value: "0.1.0 (beta)",
                valueColor: Theme.Colors.textMuted,
                showsChevron: false,
                isLast: true,
            )
        }
        .background(Color(hex: "#0C0C0C"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#161616"), lineWidth: 1),
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func settingRow(
        label: String,
        value: String,
        valueColor: Color = Theme.Colors.textMuted,
        showsChevron: Bool,
        isLast: Bool = false,
    ) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 12))
                .foregroundStyle(Theme.Colors.textPrimary)
            Spacer(minLength: 0)
            Text(value)
                .font(.system(size: 12))
                .foregroundStyle(valueColor)
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
        }
        .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
        .overlay(alignment: .bottom) {
            if !isLast {
                Rectangle()
                    .fill(Color(hex: "#0F0F0F"))
                    .frame(height: 0.5)
            }
        }
    }

    private var dangerZone: some View {
        VStack(spacing: 0) {
            Text("ACCOUNT")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#3A2A55"))
                .tracking(1.2)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 10, leading: 14, bottom: 10, trailing: 14))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(hex: "#0F0F0F"))
                        .frame(height: 0.5)
                }

            Button {
                viewModel.showResetConfirm = true
            } label: {
                Text("Reset all data")
                    .font(.system(size: 12))
                    .foregroundStyle(Color.red.opacity(0.8))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
            }
            .buttonStyle(.plain)
        }
        .background(Color(hex: "#0C0C0C"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#161616"), lineWidth: 1),
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var displayName: String {
        let trimmed = auth.onboardingPreferredName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "You" : trimmed
    }

    private var userInitials: String {
        let trimmed = auth.onboardingPreferredName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard let first = trimmed.first else { return "B" }
        return String(first).uppercased()
    }

    private var formattedWakeTime: String {
        formattedScheduleTime(forKey: "baseline.wakeTime", defaultHour: 7, defaultMinute: 0)
    }

    private var formattedCheckInTime: String {
        formattedScheduleTime(forKey: "baseline.checkInTime", defaultHour: 21, defaultMinute: 0)
    }

    private func formattedScheduleTime(forKey key: String, defaultHour: Int, defaultMinute: Int) -> String {
        let interval = UserDefaults.standard.double(forKey: key)
        let date: Date
        if interval > 0 {
            date = Date(timeIntervalSince1970: interval)
        } else {
            date = Calendar.current.date(
                bySettingHour: defaultHour,
                minute: defaultMinute,
                second: 0,
                of: Date(),
            ) ?? Date()
        }
        return Self.timeFormatter.string(from: date)
    }
}
