import SwiftUI

struct OnboardingScreen10: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var goalTexts: [String: String] = [:]
    @FocusState private var focusedField: String?
    @State private var isClassifying = false
    @State private var classificationPhaseComplete = false

    private var displayAreas: [String] {
        if onboarding.selectedLifeAreas.isEmpty {
            return ["General Goals"]
        }
        return onboarding.selectedLifeAreas
    }

    private var hasNonEmptyGoals: Bool {
        goalTexts.contains { !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    }

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                ScrollView {
                    VStack(alignment: .leading, spacing: 0) {
                        headline
                            .padding(.top, 48)

                        Text("Your coach works best when it knows exactly what you're chasing.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#8B7DFF"))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                            .padding(.horizontal, 32)

                        Text("All fields are optional — you can add detail anytime.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#3A3A3A"))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 6)
                            .padding(.horizontal, 32)

                        goalCards
                            .padding(.top, 24)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                bottomSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            for area in displayAreas {
                if goalTexts[area] == nil {
                    goalTexts[area] = ""
                }
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 2)

            HStack {
                Button(action: onBack) {
                    Text("‹")
                        .font(.system(size: 20, weight: .regular))
                        .foregroundStyle(Color(hex: "#555555"))
                        .frame(width: 32, height: 32, alignment: .leading)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
        }
    }

    // MARK: - Content

    private var headline: some View {
        (
            Text("Now let's get\n")
                .foregroundStyle(Color.white)
            + Text("specific.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 32)
    }

    private var goalCards: some View {
        VStack(spacing: 12) {
            ForEach(displayAreas, id: \.self) { area in
                GoalInputCard(
                    area: area,
                    text: Binding(
                        get: { goalTexts[area] ?? "" },
                        set: { goalTexts[area] = $0 },
                    ),
                    focusedField: $focusedField,
                    showDatePrompts: classificationPhaseComplete,
                )
            }
        }
    }

    private var bottomSection: some View {
        VStack(spacing: 8) {
            Button {
                handleContinueTap()
            } label: {
                Group {
                    if isClassifying {
                        ProgressView()
                            .tint(.white)
                            .frame(width: 20, height: 20)
                    } else {
                        Text("Continue →")
                            .font(.system(size: 17, weight: .regular))
                    }
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#7C5CBF"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)
            .disabled(isClassifying)

            Text("You can always come back and add more.")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Continue & classification

    private func handleContinueTap() {
        if classificationPhaseComplete || !hasNonEmptyGoals {
            onboarding.setGoalDetails(goalTexts)
            onNext()
            return
        }

        isClassifying = true
        Task {
            await classifyGoals()
            isClassifying = false
            withAnimation(.easeInOut(duration: 0.2)) {
                classificationPhaseComplete = true
            }
        }
    }

    private func classifyGoals() async {
        let goalEntries = goalTexts.filter {
            !$0.value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        guard !goalEntries.isEmpty else { return }

        let prompt = """
        Classify each of the following goals as either 'outcome' (has a natural deadline or measurable endpoint) or 'identity' (ongoing behavior or state with no natural deadline).

        Also extract any date mentioned in outcome goals. Return JSON only, no explanation:
        {
          "classifications": {
            "goal area": {
              "type": "outcome" or "identity",
              "extractedDate": "YYYY-MM" or null
            }
          }
        }

        Goals:
        \(goalEntries.map { "\($0.key): \($0.value)" }.joined(separator: "\n"))
        """

        do {
            let response = try await AnthropicService.shared.complete(
                model: "claude-haiku-4-5-20251001",
                prompt: prompt,
                maxTokens: 500,
            )
            if let json = Self.parseClassificationResponse(from: response) {
                onboarding.setGoalClassifications(json.classifications)
            } else {
                onboarding.setDefaultClassifications(for: Array(goalEntries.keys))
            }
        } catch {
            onboarding.setDefaultClassifications(for: Array(goalEntries.keys))
        }
    }

    private static func parseClassificationResponse(from response: String) -> GoalClassificationResponse? {
        var text = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = text.firstIndex(of: "{"), let end = text.lastIndex(of: "}") {
            text = String(text[start ... end])
        }

        guard let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(GoalClassificationResponse.self, from: data)
    }
}

// MARK: - Goal input card

private struct GoalInputCard: View {
    let area: String
    @Binding var text: String
    @FocusState.Binding var focusedField: String?
    let showDatePrompts: Bool

    @EnvironmentObject private var onboarding: OnboardingViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: GoalAreaHelpers.symbol(for: area))
                    .font(.system(size: 14, weight: .thin))
                    .foregroundStyle(Color(hex: "#8B7DFF"))

                Text(area)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(Color.white)

                Spacer(minLength: 0)
            }

            TextField(GoalAreaHelpers.placeholder(for: area), text: $text, axis: .vertical)
                .lineLimit(2)
                .font(.system(size: 14, weight: .light))
                .foregroundStyle(Color.white)
                .padding(12)
                .background(Color(hex: "#0D0D0D"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(
                            focusedField == area ? Color(hex: "#8B7DFF") : Color(hex: "#1E1E1E"),
                            lineWidth: 1,
                        ),
                )
                .focused($focusedField, equals: area)

            if showDatePrompts, onboarding.goalClassifications[area]?.type == "outcome" {
                DatePromptRow(
                    area: area,
                    extractedDate: onboarding.goalClassifications[area]?.extractedDate,
                    selectedDate: Binding(
                        get: { onboarding.goalDates[area] ?? nil },
                        set: { onboarding.setGoalDate($0, for: area) },
                    ),
                )
                .padding(.top, 8)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(16)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#2A2A2A"), lineWidth: 1),
        )
        .animation(.easeInOut(duration: 0.2), value: showDatePrompts)
    }
}

// MARK: - Date prompt

private struct DatePromptRow: View {
    let extractedDate: String?
    @Binding var selectedDate: Date?

    @State private var showPicker = false
    @State private var pickerDate: Date

    private static let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    init(area: String, extractedDate: String?, selectedDate: Binding<Date?>) {
        self.extractedDate = extractedDate
        _selectedDate = selectedDate
        let initial = selectedDate.wrappedValue
            ?? Self.date(fromExtracted: extractedDate)
            ?? Self.defaultPickerDate
        _pickerDate = State(initialValue: initial)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When do you want to achieve this by?")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))

            Button {
                if let selectedDate {
                    pickerDate = selectedDate
                } else if let suggested = Self.date(fromExtracted: extractedDate) {
                    pickerDate = suggested
                }
                showPicker = true
            } label: {
                Text(buttonLabel)
                    .font(.system(size: 13, weight: .light))
                    .foregroundStyle(selectedDate == nil ? Color(hex: "#444444") : Color.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(Color(hex: "#0D0D0D"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                    )
            }
            .buttonStyle(.plain)
        }
        .sheet(isPresented: $showPicker) {
            NavigationStack {
                DatePicker(
                    "",
                    selection: $pickerDate,
                    in: Self.minimumDate ... Self.maximumDate,
                    displayedComponents: .date,
                )
                .datePickerStyle(.graphical)
                .labelsHidden()
                .padding()
                .navigationTitle("Target date")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Skip") {
                            showPicker = false
                        }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") {
                            selectedDate = Self.startOfMonth(pickerDate)
                            showPicker = false
                        }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }

    private var buttonLabel: String {
        guard let selectedDate else { return "Select a date" }
        return Self.monthYearFormatter.string(from: selectedDate)
    }

    private static var minimumDate: Date {
        let calendar = Calendar.current
        let nextMonth = calendar.date(byAdding: .month, value: 1, to: Date()) ?? Date()
        return startOfMonth(nextMonth)
    }

    private static var maximumDate: Date {
        Calendar.current.date(byAdding: .year, value: 5, to: Date()) ?? Date()
    }

    private static var defaultPickerDate: Date {
        minimumDate
    }

    private static func startOfMonth(_ date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }

    private static func date(fromExtracted extractedDate: String?) -> Date? {
        guard let extractedDate else { return nil }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        guard let date = formatter.date(from: extractedDate) else { return nil }
        return startOfMonth(date)
    }
}

// MARK: - Area helpers

private enum GoalAreaHelpers {
    static func symbol(for area: String) -> String {
        switch area {
        case "Health & Fitness": return "heart"
        case "Career & Work": return "briefcase"
        case "Finances": return "dollarsign.circle"
        case "Relationships": return "person.2"
        case "Mental Wellbeing": return "brain"
        case "Learning & Skills": return "book"
        case "Creative Work": return "paintbrush"
        case "Lifestyle & Habits": return "moon.stars"
        default: return "plus"
        }
    }

    static func placeholder(for area: String) -> String {
        switch area {
        case "Health & Fitness": return "e.g. Run a half marathon by October"
        case "Career & Work": return "e.g. Get promoted to senior level by end of year"
        case "Finances": return "e.g. Save $10,000 emergency fund by December"
        case "Relationships": return "e.g. Be more present with the people I love"
        case "Mental Wellbeing": return "e.g. Manage anxiety and feel consistently calm"
        case "Learning & Skills": return "e.g. Finish my certification by summer"
        case "Creative Work": return "e.g. Launch my first project publicly"
        case "Lifestyle & Habits": return "e.g. Build a morning routine I actually stick to"
        default: return "Describe what you want to achieve"
        }
    }
}
