import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showGoalsSheet = false
    @State private var showFutureSelf = false
    @AppStorage("baseline.futureSelfMessage") private var futureSelfMessageStored: String = ""

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    private static let feedbackMailURL = URL(string: "mailto:feedback@resetbaseline.com")!

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
                        longTermGoalsSummaryRow
                        settingsSection
                        accountSection
                        Spacer(minLength: 20)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Theme.Colors.background)
        .sheet(isPresented: $showGoalsSheet) {
            LongTermGoalsSheetView()
                .environmentObject(auth)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showFutureSelf) {
            FutureSelfView()
                .presentationDragIndicator(.hidden)
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
                    .font(.system(size: 52, weight: .light))
                    .foregroundStyle(Color(hex: "#C4A0FF"))
                    .shadow(color: Color(hex: "#7C5CBF").opacity(0.5), radius: 12, x: 0, y: 0)
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
                    .font(.system(size: 22, weight: .ultraLight))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
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

    private var longTermGoalsSummaryRow: some View {
        Button {
            showGoalsSheet = true
        } label: {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("LONG TERM GOALS")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#3A2A55"))
                        .tracking(1.2)
                        .textCase(.uppercase)

                    HStack(spacing: 6) {
                        ForEach(Array(auth.longTermGoalDrafts.prefix(3).enumerated()), id: \.offset) { index, goal in
                            GoalMiniArcRing(progress: miniArcProgress(for: goal, index: index))
                                .frame(width: 26, height: 26)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(auth.longTermGoalDrafts.count) active goals")
                                .font(.system(size: 10))
                                .foregroundStyle(Color(hex: "#777777"))
                            Text("Tap to view progress")
                                .font(.system(size: 9))
                                .foregroundStyle(Color(hex: "#444444"))
                        }
                    }
                }

                Spacer(minLength: 0)

                Text("›")
                    .font(.system(size: 18))
                    .foregroundStyle(Color(hex: "#555555"))
            }
            .padding(EdgeInsets(top: 11, leading: 13, bottom: 11, trailing: 13))
            .background(Color(hex: "#0C0C0C"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#161616"), lineWidth: 1),
            )
        }
        .buttonStyle(.plain)
    }

    private func miniArcProgress(for goal: LongTermGoalDraft, index: Int) -> Double {
        let base = GoalProgressHelpers.quantitativeFraction(for: goal)
        let jitter = Double(index % 3) * 0.12
        return min(1, max(0.08, base + jitter - 0.06))
    }

    private var settingsSection: some View {
        VStack(spacing: 0) {
            futureSelfSettingsRow

            settingRow(
                label: "Wake time",
                value: formattedWakeTime,
                valueColor: Color(hex: "#CCCCCC"),
                showsChevron: false,
            )
            settingRow(
                label: "Check-in time",
                value: formattedCheckInTime,
                valueColor: Color(hex: "#CCCCCC"),
                showsChevron: false,
            )
            settingRow(
                label: "Notifications",
                value: "On",
                valueColor: Theme.Colors.accent,
                showsChevron: true,
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

    private var futureSelfStoredNonEmpty: Bool {
        !futureSelfMessageStored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var futureSelfSettingsRow: some View {
        Button {
            showFutureSelf = true
        } label: {
            HStack(spacing: 8) {
                Text("Message to Future Self")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer(minLength: 0)
                if futureSelfStoredNonEmpty {
                    Text("Written")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.accent)
                } else {
                    Text("Not written")
                        .font(.system(size: 10))
                        .foregroundStyle(Color(hex: "#333333"))
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(hex: "#0F0F0F"))
                    .frame(height: 0.5)
            }
        }
        .buttonStyle(.plain)
    }

    private var accountSection: some View {
        VStack(spacing: 0) {
            Text("ACCOUNT")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#3A2A55"))
                .tracking(1.2)
                .textCase(.uppercase)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(EdgeInsets(top: 9, leading: 14, bottom: 9, trailing: 14))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(hex: "#0F0F0F"))
                        .frame(height: 0.5)
                }

            Button {
                UIApplication.shared.open(Self.feedbackMailURL)
            } label: {
                HStack {
                    Text("Send feedback")
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Spacer(minLength: 0)
                    Text("Beta feedback")
                        .font(.system(size: 10))
                        .foregroundStyle(Theme.Colors.accent)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(Theme.Colors.textMuted)
                }
                .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
                .overlay(alignment: .bottom) {
                    Rectangle()
                        .fill(Color(hex: "#0F0F0F"))
                        .frame(height: 0.5)
                }
            }
            .buttonStyle(.plain)

            HStack {
                Text("Sign out")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textMuted)
                Spacer(minLength: 0)
                Text("Coming soon")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#333333"))
            }
            .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
            .overlay(alignment: .bottom) {
                Rectangle()
                    .fill(Color(hex: "#0F0F0F"))
                    .frame(height: 0.5)
            }

            HStack {
                Text("App version")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textMuted)
                Spacer(minLength: 0)
                Text("0.1.0 (beta)")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#333333"))
            }
            .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
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

// MARK: - Goal progress helpers

private enum GoalProgressHelpers {
    static func extractInts(from string: String) -> [Int] {
        var numbers: [Int] = []
        var current = ""
        for char in string {
            if char.isNumber {
                current.append(char)
            } else if !current.isEmpty {
                if let n = Int(current) { numbers.append(n) }
                current = ""
            }
        }
        if !current.isEmpty, let n = Int(current) { numbers.append(n) }
        return numbers
    }

    static func quantitativeFraction(for goal: LongTermGoalDraft) -> Double {
        let baseline = goal.currentBaseline.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !baseline.isEmpty,
              baseline.contains(where: \.isNumber)
        else {
            return 0.3
        }
        let numsB = extractInts(from: baseline)
        let numsT = extractInts(from: goal.text)
        guard let current = numsB.first else { return 0.3 }
        let target = numsT.first(where: { $0 > current }) ?? numsT.first ?? max(current * 2, current + 1)
        guard target > 0 else { return 0.3 }
        let ratio = Double(current) / Double(target)
        return min(1, max(0.05, ratio))
    }

    static func isQuantitative(_ goal: LongTermGoalDraft) -> Bool {
        let b = goal.currentBaseline.trimmingCharacters(in: .whitespacesAndNewlines)
        return !b.isEmpty && b.contains(where: \.isNumber)
    }

    static func progressLabel(for goal: LongTermGoalDraft) -> String {
        if isQuantitative(goal) {
            let pct = Int(round(quantitativeFraction(for: goal) * 100))
            return "\(pct)% toward target"
        }
        return "7-day rhythm · stay consistent"
    }
}

// MARK: - Mini arc (summary row)

private struct GoalMiniArcRing: View {
    let progress: Double

    private let lineWidth: CGFloat = 2

    var body: some View {
        Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2 - lineWidth / 2
            let bg = Path(
                ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2),
            )
            context.stroke(bg, with: .color(Color(hex: "#1A1A1A")), lineWidth: lineWidth)

            let trimmed = Path { path in
                path.addArc(
                    center: center,
                    radius: radius,
                    startAngle: .degrees(-90),
                    endAngle: .degrees(-90) + .degrees(360 * progress),
                    clockwise: false,
                )
            }
            context.stroke(trimmed, with: .color(Theme.Colors.accent), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
        }
    }
}

// MARK: - Long term goals sheet

private struct LongTermGoalsSheetView: View {
    @EnvironmentObject private var auth: AuthManager

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: "#2A2A2A"))
                .frame(width: 28, height: 3)
                .padding(.top, 10)
                .padding(.bottom, 14)

            HStack {
                Text("Long Term Goals")
                    .font(.system(size: 14, weight: .light))
                    .foregroundStyle(Color.white)
                Spacer(minLength: 0)
                Button("Edit") {}
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.accent)
                    .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            ScrollView {
                VStack(spacing: 10) {
                    ForEach(auth.longTermGoalDrafts, id: \.id) { goal in
                        LongTermGoalSheetCard(goal: goal)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
    }
}

private struct LongTermGoalSheetCard: View {
    let goal: LongTermGoalDraft

    private static let targetDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "MMM d, yyyy"
        f.locale = Locale.autoupdatingCurrent
        return f
    }()

    private var quantitative: Bool {
        GoalProgressHelpers.isQuantitative(goal)
    }

    private var fraction: Double {
        GoalProgressHelpers.quantitativeFraction(for: goal)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            if quantitative {
                QuantitativeGoalArc(fraction: fraction)
                    .frame(width: 62, height: 62)
            } else {
                QualitativeGoalArc(barFraction: 0.55)
                    .frame(width: 62, height: 62)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(goal.text)
                    .font(.system(size: 12))
                    .foregroundStyle(Color(hex: "#CCCCCC"))
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 6) {
                    sheetChip(goal.category)
                    if let date = goal.targetDate {
                        sheetChip("By \(Self.targetDateFormatter.string(from: date))")
                    }
                }

                Text(GoalProgressHelpers.progressLabel(for: goal))
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.accent)

                Text("Coach: keeping you on track.")
                    .font(.system(size: 8))
                    .italic()
                    .foregroundStyle(Color(hex: "#444444"))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(11)
        .background(Color(hex: "#0C0C0C"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#161616"), lineWidth: 1),
        )
    }

    private func sheetChip(_ text: String) -> some View {
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
}

private struct QuantitativeGoalArc: View {
    let fraction: Double

    private let lineWidth: CGFloat = 3

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - lineWidth / 2 - 2
                let bg = Path(
                    ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2),
                )
                context.stroke(bg, with: .color(Color(hex: "#1A1A1A")), lineWidth: lineWidth)

                let trimmed = Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90) + .degrees(360 * fraction),
                        clockwise: false,
                    )
                }
                context.stroke(trimmed, with: .color(Theme.Colors.accent), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
            }

            Text("\(Int(round(fraction * 100)))%")
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Theme.Colors.textPrimary)
        }
    }
}

private struct QualitativeGoalArc: View {
    let barFraction: Double

    private let lineWidth: CGFloat = 3

    var body: some View {
        VStack(spacing: 5) {
            ZStack {
                Canvas { context, size in
                    let center = CGPoint(x: size.width / 2, y: size.height / 2)
                    let radius = min(size.width, size.height) / 2 - lineWidth / 2 - 6
                    let bg = Path(
                        ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2),
                    )
                    context.stroke(bg, with: .color(Color(hex: "#1A1A1A")), lineWidth: lineWidth)

                    let trimmed = Path { path in
                        path.addArc(
                            center: center,
                            radius: radius,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(-90) + .degrees(360 * 0.48),
                            clockwise: false,
                        )
                    }
                    context.stroke(trimmed, with: .color(Color(hex: "#3D2068")), style: StrokeStyle(lineWidth: lineWidth, lineCap: .round))
                }

                Text("7")
                    .font(.system(size: 18, weight: .ultraLight))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
            }
            .frame(height: 48)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color(hex: "#1A1A1A"))
                        .frame(height: 3)
                    Capsule()
                        .fill(Color(hex: "#3D2068"))
                        .frame(width: max(4, geo.size.width * barFraction), height: 3)
                }
            }
            .frame(height: 3)
        }
    }
}
