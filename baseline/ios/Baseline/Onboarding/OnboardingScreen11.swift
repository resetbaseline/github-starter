import SwiftUI

struct OnboardingScreen11: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var isLoading = true
    @State private var anchors: [AnchorSuggestion] = []
    @State private var pulseOpacity: Double = 1.0
    @State private var loadingIndex = 0
    @State private var showAddField = false
    @State private var customAnchorText = ""
    @State private var loadingCycleTask: Task<Void, Never>?

    private let loadingCopy = [
        "Reading your goals...",
        "Mapping your patterns...",
        "Building your first day...",
    ]

    private var canContinue: Bool {
        !anchors.isEmpty
    }

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            if isLoading {
                loadingView
            } else {
                anchorsView
            }
        }
        .onAppear {
            startLoadingCopyCycle()
            Task {
                await loadAnchorsWithMinimumDelay()
            }
        }
        .onDisappear {
            loadingCycleTask?.cancel()
            loadingCycleTask = nil
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: 24) {
            CoachPeakIcon(size: 64)
                .opacity(pulseOpacity)
                .onAppear {
                    withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                        pulseOpacity = 0.4
                    }
                }

            Text(loadingCopy[loadingIndex])
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .transition(.opacity)
                .id(loadingIndex)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .animation(.easeInOut(duration: 0.4), value: loadingIndex)
    }

    // MARK: - Anchors

    private var anchorsView: some View {
        VStack(spacing: 0) {
            topBar
                .padding(.top, 24)
                .padding(.horizontal, 20)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    headline
                        .padding(.top, 32)

                    Text("These are your anchors — the actions that move you forward. Remove or edit any that don't feel right.")
                        .font(.system(size: 14, weight: .light))
                        .foregroundStyle(Color(hex: "#555555"))
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.top, 10)
                        .padding(.horizontal, 32)

                    anchorCards
                        .padding(.top, 24)

                    addAnchorSection
                        .padding(.top, 16)

                    Text("You can edit these anytime from your profile.")
                        .font(.system(size: 13, weight: .light))
                        .foregroundStyle(Color(hex: "#555555"))
                        .padding(.top, 16)
                        .padding(.horizontal, 32)
                }
                .padding(.bottom, 16)
            }
            .scrollDismissesKeyboard(.interactively)

            continueButton
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

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

    private var headline: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Your coach built")
                .foregroundStyle(Color.white)
            Text("your first day.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        }
        .font(.system(size: 36, weight: .light, design: .serif))
        .padding(.horizontal, 32)
    }

    private var anchorCards: some View {
        VStack(spacing: 12) {
            ForEach($anchors) { $anchor in
                AnchorCard(
                    anchor: $anchor,
                    onRemove: { removeAnchor(id: anchor.id) },
                )
            }
        }
        .padding(.horizontal, 32)
    }

    private var addAnchorSection: some View {
        VStack(spacing: 12) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    showAddField = true
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "plus")
                        .font(.system(size: 14))
                    Text("Add your own anchor")
                        .font(.system(size: 14, weight: .light))
                }
                .foregroundStyle(Color(hex: "#444444"))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [6]))
                        .foregroundStyle(Color(hex: "#2A2A2A")),
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)

            if showAddField {
                HStack(spacing: 12) {
                    TextField("What's your anchor?", text: $customAnchorText)
                        .font(.system(size: 15, weight: .light))
                        .foregroundStyle(Color.white)
                        .padding(14)
                        .background(Color(hex: "#111111"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(hex: "#8B7DFF"), lineWidth: 1),
                        )

                    Button {
                        let trimmed = customAnchorText.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !trimmed.isEmpty else { return }
                        withAnimation(.easeInOut(duration: 0.2)) {
                            anchors.append(
                                AnchorSuggestion(
                                    text: trimmed,
                                    area: "Custom",
                                    goal: "",
                                ),
                            )
                            customAnchorText = ""
                            showAddField = false
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(Color.white)
                            .frame(width: 44, height: 44)
                            .background(Color(hex: "#7C5CBF"))
                            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 32)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }

    private var continueButton: some View {
        Button {
            onboarding.setAnchors(
                anchors.map {
                    OnboardingAnchor(
                        text: $0.text,
                        area: $0.area,
                        timeBlock: $0.timeBlock,
                    )
                },
            )
            onNext()
        } label: {
            Text("Continue →")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(canContinue ? Color.white : Color(hex: "#333333"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(canContinue ? Color(hex: "#7C5CBF") : Color(hex: "#1A1A1A"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            canContinue ? Color.clear : Color(hex: "#2A2A2A"),
                            lineWidth: 1,
                        ),
                )
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
        .animation(.easeInOut(duration: 0.2), value: canContinue)
    }

    // MARK: - Loading & generation

    private func startLoadingCopyCycle() {
        loadingCycleTask?.cancel()
        loadingCycleTask = Task {
            while !Task.isCancelled, isLoading {
                try? await Task.sleep(nanoseconds: 1_500_000_000)
                guard !Task.isCancelled, isLoading else { break }
                await MainActor.run {
                    loadingIndex = (loadingIndex + 1) % loadingCopy.count
                }
            }
        }
    }

    private func loadAnchorsWithMinimumDelay() async {
        let started = Date()
        let generated = await fetchAnchors()
        let elapsed = Date().timeIntervalSince(started)
        if elapsed < 2 {
            try? await Task.sleep(nanoseconds: UInt64((2 - elapsed) * 1_000_000_000))
        }
        withAnimation(.easeInOut(duration: 0.5)) {
            anchors = generated
            isLoading = false
        }
        loadingCycleTask?.cancel()
    }

    private func fetchAnchors() async -> [AnchorSuggestion] {
        let prompt = buildAnchorPrompt()

        do {
            let response = try await AnthropicService.shared.complete(
                model: "claude-haiku-4-5-20251001",
                prompt: prompt,
                maxTokens: 1000,
            )
            if let parsed = Self.parseAnchors(from: response) {
                return parsed
            }
        } catch {}

        return fallbackAnchors()
    }

    private func buildAnchorPrompt() -> String {
        let goals = onboarding.goalDetails.map { area, goal in
            let classification = onboarding.goalClassifications[area]?.type ?? "outcome"
            let dateStr = onboarding.goalDates[area].flatMap { $0 }.map {
                DateFormatter.localizedString(from: $0, dateStyle: .medium, timeStyle: .none)
            } ?? "no deadline"
            return "- \(area): \(goal) (\(classification), \(dateStr))"
        }.joined(separator: "\n")

        let patterns = onboarding.behavioralPatterns.joined(separator: ", ")
        let distractions = onboarding.distractions.joined(separator: ", ")
        let timeWindow = onboarding.vulnerableTimeWindow ?? "unspecified"
        let name = onboarding.preferredName.isEmpty ? "the user" : onboarding.preferredName

        return """
        You are a behavioral coach for \(name). Generate one specific daily anchor (action) per goal listed below.

        User context:
        - Behavioral patterns: \(patterns)
        - Main distractions: \(distractions)
        - Most vulnerable time: \(timeWindow)

        Goals:
        \(goals.isEmpty ? "- General: make meaningful progress today" : goals)

        Rules:
        - One anchor per goal, specific and actionable
        - For outcome goals with deadlines, calibrate urgency to timeline
        - For identity goals, suggest a consistent daily practice
        - Keep each anchor under 8 words
        - Reference the specific goal, not a generic action
        - Return JSON only:
        {
          "anchors": [
            {
              "text": "anchor text here",
              "area": "life area name",
              "goal": "the goal this is based on"
            }
          ]
        }
        """
    }

    private func fallbackAnchors() -> [AnchorSuggestion] {
        let areas: [String]
        if !onboarding.selectedLifeAreas.isEmpty {
            areas = onboarding.selectedLifeAreas
        } else if !onboarding.goalDetails.isEmpty {
            areas = Array(onboarding.goalDetails.keys)
        } else {
            return [
                AnchorSuggestion(
                    text: "One meaningful action today",
                    area: "General Goals",
                    goal: "",
                ),
            ]
        }

        return areas.map { area in
            AnchorSuggestion(
                text: "Daily action for \(area.lowercased())",
                area: area,
                goal: onboarding.goalDetails[area] ?? "",
            )
        }
    }

    private func removeAnchor(id: UUID) {
        withAnimation(.easeInOut(duration: 0.2)) {
            anchors.removeAll { $0.id == id }
        }
    }

    private static func parseAnchors(from response: String) -> [AnchorSuggestion]? {
        var clean = response
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let start = clean.firstIndex(of: "{"), let end = clean.lastIndex(of: "}") {
            clean = String(clean[start ... end])
        }

        guard let data = clean.data(using: .utf8),
              let json = try? JSONDecoder().decode(AnchorResponse.self, from: data)
        else {
            return nil
        }

        return json.anchors.map {
            AnchorSuggestion(text: $0.text, area: $0.area, goal: $0.goal)
        }
    }
}

// MARK: - Models

private struct AnchorSuggestion: Identifiable, Equatable {
    let id = UUID()
    var text: String
    let area: String
    let goal: String
    var timeBlock: String?
    var isEditing = false
}

private struct AnchorResponse: Codable {
    let anchors: [AnchorPayload]
}

private struct AnchorPayload: Codable {
    let text: String
    let area: String
    let goal: String
}

// MARK: - Anchor card

private struct AnchorCard: View {
    @Binding var anchor: AnchorSuggestion
    let onRemove: () -> Void
    @FocusState private var isEditFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                if anchor.isEditing {
                    TextField("Edit anchor...", text: $anchor.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.white)
                        .focused($isEditFocused)
                        .onAppear { isEditFocused = true }
                } else {
                    Text(anchor.text)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Spacer(minLength: 0)

                HStack(spacing: 12) {
                    if anchor.isEditing {
                        Button("Done") {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                anchor.isEditing = false
                            }
                        }
                        .font(.system(size: 13, weight: .regular))
                        .foregroundStyle(Color(hex: "#8B7DFF"))
                        .buttonStyle(.plain)
                    } else {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                anchor.isEditing = true
                            }
                        } label: {
                            Image(systemName: "pencil")
                                .font(.system(size: 11))
                                .foregroundStyle(Color(hex: "#444444"))
                        }
                        .buttonStyle(.plain)
                        .frame(width: 24, height: 24)
                    }

                    Button(action: onRemove) {
                        Image(systemName: "xmark")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "#444444"))
                    }
                    .buttonStyle(.plain)
                    .frame(width: 24, height: 24)
                }
            }

            HStack(spacing: 4) {
                Image(systemName: "arrow.up")
                    .font(.system(size: 10))
                Text(anchor.area)
                    .font(.system(size: 12, weight: .light))
            }
            .foregroundStyle(Color(hex: "#8B7DFF"))

            TimeBlockRow(
                selectedBlock: Binding(
                    get: { anchor.timeBlock },
                    set: { anchor.timeBlock = $0 },
                ),
            )
        }
        .padding(16)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(
                    anchor.isEditing ? Color(hex: "#A080FF") : Color(hex: "#8B7DFF"),
                    lineWidth: 1,
                ),
        )
    }
}

// MARK: - Time block

private struct TimeBlockRow: View {
    @Binding var selectedBlock: String?
    @State private var isExpanded = false

    private let blocks = ["Morning", "Afternoon", "Evening"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus")
                        .font(.system(size: 11))
                    Text(selectedBlock ?? "Add a time")
                        .font(.system(size: 13, weight: .light))
                }
                .foregroundStyle(selectedBlock != nil ? Color(hex: "#8B7DFF") : Color(hex: "#444444"))
            }
            .buttonStyle(.plain)

            if isExpanded {
                HStack(spacing: 8) {
                    ForEach(blocks, id: \.self) { block in
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedBlock = selectedBlock == block ? nil : block
                                isExpanded = false
                            }
                        } label: {
                            Text(block)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(selectedBlock == block ? Color.white : Color(hex: "#888888"))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(selectedBlock == block ? Color(hex: "#1A0D35") : Color(hex: "#161616"))
                                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .stroke(
                                            selectedBlock == block ? Color(hex: "#8B7DFF") : Color(hex: "#2A2A2A"),
                                            lineWidth: 1,
                                        ),
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
    }
}
