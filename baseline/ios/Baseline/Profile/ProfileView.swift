import SwiftUI
import UIKit

struct ProfileView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var viewModel = ProfileViewModel()
    @State private var showGoalsSheet = false
    @State private var showFutureSelf = false
    @State private var showSettings = false
    @State private var showSupport = false
    @State private var supportInitialCategory: SupportCategory?
    @State private var showFreezeExplainer = false
    @AppStorage("baseline.futureSelfMessage") private var futureSelfMessageStored: String = ""

    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()

    var body: some View {
        ZStack {
            Color(hex: "#0A0814")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 12) {
                        identityCard
                        streakCard
                        longTermGoalsSection
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 20)
                }
            }
        }
        .sheet(isPresented: $showGoalsSheet) {
            LongTermGoalsSheetView()
                .environmentObject(auth)
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showFutureSelf) {
            FutureSelfView()
                .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSettings) {
            SettingsSheetView(
                futureSelfWritten: futureSelfStoredNonEmpty,
                formattedWakeTime: formattedWakeTime,
                formattedCheckInTime: formattedCheckInTime,
                onFutureSelf: {
                    showSettings = false
                    showFutureSelf = true
                },
                onContactSupport: {
                    showSettings = false
                    supportInitialCategory = nil
                    showSupport = true
                },
                onBetaFeedback: {
                    showSettings = false
                    supportInitialCategory = .betaFeedback
                    showSupport = true
                },
            )
            .presentationDragIndicator(.hidden)
        }
        .sheet(isPresented: $showSupport, onDismiss: { supportInitialCategory = nil }) {
            SupportView(initialCategory: supportInitialCategory)
                .presentationDragIndicator(.hidden)
        }
        .sheet(item: $viewModel.selectedDay) { day in
            DayDetailView(
                day: day,
                freezesRemaining: viewModel.freezesRemaining,
                onFreeze: {
                    viewModel.applyFreeze(day: day.day, month: day.month, year: day.year)
                },
            )
            .presentationDetents([.medium])
            .presentationDragIndicator(.hidden)
        }
        .alert("❄️ Streak Freezes", isPresented: $showFreezeExplainer) {
            Button("Got it", role: .cancel) {}
        } message: {
            Text(
                "You earn 1 freeze for every 7 consecutive check-in days. Tap any missed day on the calendar to apply one — it protects your streak for that day. Freezes never expire and have no limit.",
            )
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Profile")
                .font(.system(size: 28, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)

            Spacer(minLength: 0)

            Button {
                showSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.top, 52)
        .padding(.bottom, 8)
    }

    // MARK: - Identity

    private var identityCard: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color(hex: "#1A1030"))
                    .frame(width: 56, height: 56)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                    )
                CoachPeakIcon(size: 32)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(displayName)
                    .font(.system(size: 20, weight: .light))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text(viewModel.memberSinceFormatted)
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textMuted)

                Spacer(minLength: 0)
                    .frame(height: 8)

                HStack(spacing: 0) {
                    profileStat(value: "\(viewModel.totalGoalsCompleted)", label: "GOALS")
                    profileStat(value: viewModel.totalFocusHours, label: "FOCUS")
                    profileStat(value: "\(viewModel.totalCheckIns)", label: "CHECK-INS")
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Color(hex: "#0F0A1A"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#1E1430"), lineWidth: 1),
        )
    }

    private func profileStat(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 18, weight: .ultraLight))
                .foregroundStyle(Color(hex: "#7C5CBF"))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Text(label)
                .font(.system(size: 7))
                .foregroundStyle(Color(hex: "#444444"))
                .tracking(1.2)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Streak card

    private var streakCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .trailing) {
                streakCardTop

                GeometryReader { geo in
                    MountainSilhouette()
                        .frame(width: 120, height: 90)
                        .position(x: geo.size.width - 60, y: 45)
                }
                .allowsHitTesting(false)
            }
            .frame(minHeight: 110)

            freezeBar

            StreakCalendarView(
                calendarData: $viewModel.calendarData,
                selectedDay: $viewModel.selectedDay,
            )
        }
        .background(Color(hex: "#0A0610"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color(hex: "#1E1430"), lineWidth: 1),
        )
    }

    private var streakCardTop: some View {
        HStack(alignment: .top, spacing: 0) {
            VStack(alignment: .leading, spacing: 2) {
                Text("CURRENT STREAK")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#5A3A90"))
                    .tracking(2)
                    .textCase(.uppercase)

                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(viewModel.streakCurrent)")
                        .font(.system(size: 52, weight: .light))
                        .foregroundStyle(Color(hex: "#C4A0FF"))
                        .shadow(color: Color(hex: "#7C5CBF").opacity(0.5), radius: 20, x: 0, y: 0)

                    Text("day streak")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#7C5CBF"))
                        .padding(.bottom, 8)
                }

                Text(viewModel.streakTagline)
                    .font(.system(size: 10))
                    .italic()
                    .foregroundStyle(Color(hex: "#7C5CBF"))
                    .opacity(0.8)
            }

            Spacer(minLength: 0)

            VStack(alignment: .trailing, spacing: 2) {
                Text("BEST STREAK")
                    .font(.system(size: 7))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .tracking(1)
                    .textCase(.uppercase)

                HStack(alignment: .center, spacing: 3) {
                    Text("🔥")
                        .font(.system(size: 16))
                    Text("\(viewModel.streakMax)")
                        .font(.system(size: 24, weight: .light))
                        .foregroundStyle(Color(hex: "#C4A0FF"))
                }

                Text("days")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#5A3A70"))
            }
            .padding(.top, 4)
        }
        .padding(16)
    }

    private var freezeBar: some View {
        HStack(spacing: 6) {
            Text("❄️")
                .font(.system(size: 12))
            Text("\(viewModel.freezesRemaining)")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#6AA0DC"))
            Text("freezes banked")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#4A6A9A"))

            Spacer(minLength: 0)

            Text("Tap a missed day to use one")
                .font(.system(size: 7))
                .foregroundStyle(Color(hex: "#2A3A4A"))
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 16)
        .background(Color(hex: "#060310"))
        .overlay(alignment: .top) {
            Rectangle()
                .fill(Color(hex: "#0F0820"))
                .frame(height: 0.5)
        }
        .onLongPressGesture {
            showFreezeExplainer = true
        }
    }

    // MARK: - Long term goals

    private var longTermGoalsSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Long Term Goals")
                    .font(.system(size: 16, weight: .light))
                    .foregroundStyle(Theme.Colors.textPrimary)

                Spacer(minLength: 0)

                Button {
                    showGoalsSheet = true
                } label: {
                    HStack(spacing: 3) {
                        Text("\(auth.longTermGoalDrafts.count) active")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.accent)
                        Image(systemName: "chevron.right")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.accent)
                    }
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.top, 4)
            .padding(.bottom, 8)

            if auth.longTermGoalDrafts.isEmpty {
                Text("No long term goals yet.")
                    .font(.system(size: 10))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)

                Button("Add goals") {
                    showGoalsSheet = true
                }
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.accent)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 4)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(auth.longTermGoalDrafts) { goal in
                            GoalTileView(goal: goal) {
                                showGoalsSheet = true
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 4)
                }
            }
        }
    }

    // MARK: - Helpers

    private var futureSelfStoredNonEmpty: Bool {
        !futureSelfMessageStored.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var displayName: String {
        let trimmed = auth.onboardingPreferredName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? "You" : trimmed
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

// MARK: - Mountain silhouette

private struct MountainSilhouette: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: 0, y: size.height))
            path.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.18))
            path.addLine(to: CGPoint(x: size.width * 0.62, y: size.height * 0.42))
            path.addLine(to: CGPoint(x: size.width, y: size.height * 0.08))
            path.addLine(to: CGPoint(x: size.width, y: size.height))
            path.closeSubpath()
            context.fill(path, with: .color(Color(hex: "#1A0F2A").opacity(0.8)))
        }
    }
}

// MARK: - Calendar

private struct StreakCalendarView: View {
    @Binding var calendarData: [String: [Int: DayState]]
    @Binding var selectedDay: SelectedDay?

    @State private var displayMonth: Int
    @State private var displayYear: Int

    private static let weekdaySymbols = ["S", "M", "T", "W", "T", "F", "S"]

    init(calendarData: Binding<[String: [Int: DayState]]>, selectedDay: Binding<SelectedDay?>) {
        _calendarData = calendarData
        _selectedDay = selectedDay
        let now = Date()
        let calendar = Calendar.current
        _displayMonth = State(initialValue: calendar.component(.month, from: now))
        _displayYear = State(initialValue: calendar.component(.year, from: now))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(action: prevMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#5A3A90"))
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                Text(monthYearString)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#9B7FD4"))

                Spacer(minLength: 0)

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color(hex: "#5A3A90"))
                }
                .buttonStyle(.plain)
            }

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                ForEach(Self.weekdaySymbols, id: \.self) { symbol in
                    Text(symbol)
                        .font(.system(size: 7))
                        .foregroundStyle(Color(hex: "#222222"))
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 3), count: 7), spacing: 3) {
                ForEach(0 ..< calendarCellCount, id: \.self) { index in
                    if index < firstWeekdayOffset {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    } else {
                        let day = index - firstWeekdayOffset + 1
                        let state = dayState(for: day)
                        StreakDayCell(
                            day: day,
                            state: state,
                            isToday: isToday(day: day),
                        ) {
                            selectedDay = SelectedDay(
                                day: day,
                                month: displayMonth,
                                year: displayYear,
                                state: state,
                            )
                        }
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    private var monthKey: String {
        ProfileViewModel.monthKey(year: displayYear, month: displayMonth)
    }

    private var monthYearString: String {
        let components = DateComponents(year: displayYear, month: displayMonth, day: 1)
        guard let date = Calendar.current.date(from: components) else { return "" }
        return Self.monthYearFormatter.string(from: date)
    }

    private var daysInMonth: Int {
        var components = DateComponents(year: displayYear, month: displayMonth, day: 1)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: date)
        else { return 30 }
        return range.count
    }

    private var firstWeekdayOffset: Int {
        var components = DateComponents(year: displayYear, month: displayMonth, day: 1)
        let calendar = Calendar.current
        guard let date = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: date) - 1
    }

    private var calendarCellCount: Int {
        firstWeekdayOffset + daysInMonth
    }

    private func dayState(for day: Int) -> DayState {
        calendarData[monthKey]?[day] ?? .empty
    }

    private func isToday(day: Int) -> Bool {
        let now = Date()
        let calendar = Calendar.current
        return calendar.component(.day, from: now) == day
            && calendar.component(.month, from: now) == displayMonth
            && calendar.component(.year, from: now) == displayYear
    }

    private func prevMonth() {
        if displayMonth == 1 {
            displayMonth = 12
            displayYear -= 1
        } else {
            displayMonth -= 1
        }
    }

    private func nextMonth() {
        if displayMonth == 12 {
            displayMonth = 1
            displayYear += 1
        } else {
            displayMonth += 1
        }
    }

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
}

private struct StreakDayCell: View {
    let day: Int
    let state: DayState
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 0) {
                Text("\(day)")
                    .font(dayFont)
                    .foregroundStyle(numberColor)

                if state == .strong {
                    Text("🔥")
                        .font(.system(size: 7))
                } else if state == .freeze {
                    Text("❄️")
                        .font(.system(size: 7))
                } else {
                    Spacer(minLength: 0)
                        .frame(height: 7)
                }
            }
            .frame(maxWidth: .infinity)
            .aspectRatio(1, contentMode: .fit)
            .background(fillColor)
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(borderColor, lineWidth: 0.5),
            )
            .overlay {
                if isToday {
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color(hex: "#C4A0FF"), lineWidth: 1.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private var dayFont: Font {
        state == .strong
            ? .system(size: 8, weight: .bold)
            : .system(size: 8, weight: .regular)
    }

    private var fillColor: Color {
        switch state {
        case .strong: Color(hex: "#7C3FD4")
        case .solid: Color(hex: "#5A2FA8")
        case .light: Color(hex: "#1A0D30")
        case .skipped: Color(hex: "#080510")
        case .freeze: Color(hex: "#0D2035")
        case .future, .empty: Color.clear
        }
    }

    private var borderColor: Color {
        switch state {
        case .strong: Color(hex: "#A060F0")
        case .solid: Color(hex: "#8050CC")
        case .light: Color(hex: "#2D1855")
        case .skipped: Color(hex: "#100A1A")
        case .freeze: Color(hex: "#2A5A8A")
        case .future, .empty: Color(hex: "#0E0A14")
        }
    }

    private var numberColor: Color {
        switch state {
        case .strong: Color(hex: "#FFFFFF")
        case .solid: Color(hex: "#D4AAFF")
        case .light: Color(hex: "#5A3A80")
        case .skipped: Color(hex: "#221830")
        case .freeze: Color(hex: "#7AAEDD")
        case .future, .empty: Color(hex: "#120E1A")
        }
    }
}

// MARK: - Day detail

private struct DayDetailView: View {
    @Environment(\.dismiss) private var dismiss

    let day: SelectedDay
    let freezesRemaining: Int
    let onFreeze: () -> Void

    @State private var showFreezeConfirm = false

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: "#2A2A2A"))
                .frame(width: 24, height: 3)
                .padding(.top, 10)
                .padding(.bottom, 14)

            Text(formattedDate.uppercased())
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#5A3A90"))
                .tracking(1)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            Text(stateTitle)
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 10)

            Text(stateDescription)
                .font(.system(size: 11))
                .foregroundStyle(Theme.Colors.textMuted)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 6)

            if day.state == .skipped {
                freezeButtonCard
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
            }

            Spacer(minLength: 0)

            Button("Dismiss") {
                dismiss()
            }
            .font(.system(size: 9))
            .foregroundStyle(Color(hex: "#333333"))
            .buttonStyle(.plain)
            .padding(.bottom, 20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Color(hex: "#09050F"))
        .alert("Use a streak freeze?", isPresented: $showFreezeConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Use freeze", role: .destructive) {
                onFreeze()
                dismiss()
            }
        } message: {
            Text(
                "This will use 1 of your \(freezesRemaining) freezes. Your streak will be protected for this day. This cannot be undone.",
            )
        }
    }

    private var freezeButtonCard: some View {
        Button {
            if freezesRemaining > 0 {
                showFreezeConfirm = true
            }
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text("❄️ Use a freeze")
                        .font(.system(size: 11))
                        .foregroundStyle(Color(hex: "#6AA0DC"))
                    Spacer(minLength: 0)
                    Text("\(freezesRemaining) available")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#2A4A7A"))
                }

                Text("Tap to protect your streak for this day")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#2A4A7A"))
            }
            .padding(12)
            .background(Color(hex: "#0A1828"))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color(hex: "#2A4A7A"), lineWidth: 1),
            )
        }
        .buttonStyle(.plain)
        .disabled(freezesRemaining == 0)
        .opacity(freezesRemaining == 0 ? 0.4 : 1)
    }

    private var formattedDate: String {
        var components = DateComponents(year: day.year, month: day.month, day: day.day)
        guard let date = Calendar.current.date(from: components) else { return "" }
        return Self.detailDateFormatter.string(from: date)
    }

    private var stateTitle: String {
        switch day.state {
        case .strong: "🔥 Strong day"
        case .solid: "✓ Solid day"
        case .light: "~ Light day"
        case .freeze: "❄️ Freeze used"
        case .skipped: "Missed day"
        case .future: "Upcoming"
        case .empty: "No data"
        }
    }

    private var stateDescription: String {
        switch day.state {
        case .strong:
            "All non-negotiables done and reflection submitted."
        case .solid:
            "Progress made — some goals done or reflection submitted."
        case .light:
            "Checked in but nothing completed. Streak still counts."
        case .freeze:
            "A streak freeze protected this day."
        case .skipped:
            "No check-in recorded."
        case .future:
            "This day hasn't happened yet."
        case .empty:
            "No activity recorded for this day."
        }
    }

    private static let detailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        formatter.locale = Locale.autoupdatingCurrent
        return formatter
    }()
}

// MARK: - Goal tile

private struct GoalTileView: View {
    let goal: LongTermGoalDraft
    let onTap: () -> Void

    private var progressFraction: Double {
        GoalProgressHelpers.quantitativeFraction(for: goal)
    }

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .top) {
                    ZStack {
                        Circle()
                            .fill(Color(hex: "#1A1228"))
                            .frame(width: 28, height: 28)
                            .overlay(
                                Circle()
                                    .stroke(Color(hex: "#2D1F4A"), lineWidth: 0.5),
                            )
                        Image(systemName: GoalIconHelpers.icon(for: goal))
                            .font(.system(size: 13))
                            .foregroundStyle(Theme.Colors.accent)
                    }

                    Spacer(minLength: 0)

                    GoalTileMiniArc(fraction: progressFraction)
                        .frame(width: 36, height: 36)
                }

                Text(goal.text)
                    .font(.system(size: 10, weight: .light))
                    .foregroundStyle(Color(hex: "#CCCCCC"))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)

                Text(goal.currentBaseline.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? goal.category : goal.currentBaseline)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#555555"))
                    .lineLimit(1)
            }
            .padding(10)
            .frame(width: 120, alignment: .leading)
            .background(Color(hex: "#0F0A1A"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#1E1430"), lineWidth: 0.5),
            )
        }
        .buttonStyle(.plain)
    }
}

private struct GoalTileMiniArc: View {
    let fraction: Double

    var body: some View {
        ZStack {
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = min(size.width, size.height) / 2 - 2
                let bg = Path(
                    ellipseIn: CGRect(x: center.x - radius, y: center.y - radius, width: radius * 2, height: radius * 2),
                )
                context.stroke(bg, with: .color(Color(hex: "#1A1A1A")), lineWidth: 2)

                let trimmed = Path { path in
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(-90) + .degrees(360 * fraction),
                        clockwise: false,
                    )
                }
                context.stroke(trimmed, with: .color(Theme.Colors.accent), style: StrokeStyle(lineWidth: 2, lineCap: .round))
            }

            Text("\(Int(round(fraction * 100)))%")
                .font(.system(size: 8))
                .foregroundStyle(Color.white)
        }
    }
}

// MARK: - Settings sheet

private struct SettingsSheetView: View {
    let futureSelfWritten: Bool
    let formattedWakeTime: String
    let formattedCheckInTime: String
    let onFutureSelf: () -> Void
    let onContactSupport: () -> Void
    let onBetaFeedback: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                .fill(Color(hex: "#2A2A2A"))
                .frame(width: 28, height: 3)
                .padding(.top, 10)
                .padding(.bottom, 14)

            Text("Settings")
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .padding(.bottom, 12)

            VStack(spacing: 0) {
                settingsButtonRow(label: "Message to Future Self", action: onFutureSelf) {
                    if futureSelfWritten {
                        Text("Written")
                            .font(.system(size: 10))
                            .foregroundStyle(Theme.Colors.accent)
                    } else {
                        Text("Not written")
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#333333"))
                    }
                }

                settingsValueRow(label: "Wake time", value: formattedWakeTime, valueColor: Color(hex: "#CCCCCC"))
                settingsValueRow(label: "Check-in time", value: formattedCheckInTime, valueColor: Color(hex: "#CCCCCC"))
                settingsValueRow(
                    label: "Notifications",
                    value: "On",
                    valueColor: Theme.Colors.accent,
                    showsChevron: true,
                    isLastInGroup: true,
                )

                settingsDivider

                settingsButtonRow(label: "Contact Support", action: onContactSupport)
                settingsButtonRow(label: "Send beta feedback", action: onBetaFeedback, isLastInGroup: true)

                settingsDivider

                settingsValueRow(
                    label: "App version",
                    value: "0.1.0 (beta)",
                    valueColor: Color(hex: "#333333"),
                    isLastInGroup: true,
                )
            }
            .background(Color(hex: "#0C0C0C"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color(hex: "#161616"), lineWidth: 1),
            )
            .padding(.horizontal, 16)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .background(Theme.Colors.background)
    }

    private var settingsDivider: some View {
        Rectangle()
            .fill(Color(hex: "#0F0F0F"))
            .frame(height: 0.5)
            .padding(.horizontal, 14)
    }

    private func settingsButtonRow<Trailing: View>(
        label: String,
        action: @escaping () -> Void,
        isLastInGroup: Bool = false,
        @ViewBuilder trailing: () -> Trailing = { EmptyView() },
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(label)
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Spacer(minLength: 0)
                trailing()
                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            .padding(EdgeInsets(top: 13, leading: 14, bottom: 13, trailing: 14))
            .overlay(alignment: .bottom) {
                if !isLastInGroup {
                    Rectangle()
                        .fill(Color(hex: "#0F0F0F"))
                        .frame(height: 0.5)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func settingsValueRow(
        label: String,
        value: String,
        valueColor: Color,
        showsChevron: Bool = false,
        isLastInGroup: Bool = false,
    ) -> some View {
        HStack(spacing: 8) {
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
            if !isLastInGroup {
                Rectangle()
                    .fill(Color(hex: "#0F0F0F"))
                    .frame(height: 0.5)
            }
        }
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
            ZStack {
                Circle()
                    .fill(Color(hex: "#1A1228"))
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                    )
                Image(systemName: GoalIconHelpers.icon(for: goal))
                    .font(.system(size: 16))
                    .foregroundStyle(Theme.Colors.accent)
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
