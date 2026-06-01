import SwiftUI

struct OnboardingScreen5: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var selectedPatterns: Set<String> = []
    @State private var otherText: String = ""
    @State private var showOtherField: Bool = false
    @FocusState private var otherFieldFocused: Bool

    private let patterns: [(label: String, sublabel: String)] = [
        ("Lack of discipline", "I know what to do. I just don't do it."),
        ("My environment", "Everything around me pulls me off course."),
        ("I get overwhelmed", "Tasks pile up and I shut down completely."),
        ("Don't know where to start", "The distance between now and the goal feels too large."),
        ("I lose momentum", "One bad day and the whole streak falls apart."),
        ("Stress and anxiety", "My mental state derails my intentions."),
        ("Other", "Something else is getting in the way."),
    ]

    private var canContinue: Bool {
        !selectedPatterns.isEmpty
    }

    private var trimmedOtherText: String {
        otherText.trimmingCharacters(in: .whitespacesAndNewlines)
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

                        Text("Select everything that feels true.")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .padding(.top, 16)

                        cardList
                            .padding(.top, 32)

                        if showOtherField {
                            otherField
                                .padding(.top, 10)
                                .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        Text("Your coach uses this to anticipate obstacles before they happen.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .scrollDismissesKeyboard(.interactively)

                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 1)

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
            Text("What pattern\n")
                .foregroundStyle(Color.white)
            + Text("keeps repeating?")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var cardList: some View {
        VStack(spacing: 10) {
            ForEach(patterns, id: \.label) { pattern in
                patternCard(label: pattern.label, sublabel: pattern.sublabel)
            }
        }
    }

    private func patternCard(label: String, sublabel: String) -> some View {
        let isSelected = selectedPatterns.contains(label)

        return Button {
            togglePattern(label)
        } label: {
            ZStack(alignment: .trailing) {
                VStack(alignment: .leading, spacing: 3) {
                    Text(label)
                        .font(.system(size: 15, weight: .regular))
                        .foregroundStyle(isSelected ? Color.white : Color(hex: "#888888"))
                        .multilineTextAlignment(.leading)

                    Text(sublabel)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(isSelected ? Color(hex: "#8B7DFF") : Color(hex: "#444444"))
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.9)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.leading, 16)
                .padding(.trailing, 40)
                .padding(.vertical, 14)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#8B7DFF"))
                        .padding(.trailing, 16)
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .leading)
            .fixedSize(horizontal: false, vertical: true)
            .background(isSelected ? Color(hex: "#1A0D35") : Color(hex: "#161616"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        isSelected ? Color(hex: "#8B7DFF") : Color(hex: "#2A2A2A"),
                        lineWidth: 1,
                    ),
            )
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }

    private var otherField: some View {
        TextField(
            "",
            text: $otherText,
            prompt: Text("Describe the pattern...")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color(hex: "#444444")),
        )
        .font(.system(size: 15, weight: .light))
        .foregroundStyle(Color.white)
        .textInputAutocapitalization(.sentences)
        .autocorrectionDisabled()
        .focused($otherFieldFocused)
        .padding(.horizontal, 16)
        .frame(height: 44)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    otherFieldFocused ? Color(hex: "#8B7DFF") : Color(hex: "#2A2A2A"),
                    lineWidth: 1,
                ),
        )
    }

    private var continueButton: some View {
        Button {
            onboarding.setBehavioralPatterns(buildPatterns())
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

    // MARK: - Actions

    private func togglePattern(_ label: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedPatterns.contains(label) {
                selectedPatterns.remove(label)
                if label == "Other" {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showOtherField = false
                    }
                    otherText = ""
                    otherFieldFocused = false
                }
            } else {
                selectedPatterns.insert(label)
                if label == "Other" {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showOtherField = true
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                        otherFieldFocused = true
                    }
                }
            }
        }
    }

    private func buildPatterns() -> [String] {
        var result = selectedPatterns.sorted()
        if selectedPatterns.contains("Other"), !trimmedOtherText.isEmpty {
            result.removeAll { $0 == "Other" }
            result.append(trimmedOtherText)
        }
        return result
    }
}
