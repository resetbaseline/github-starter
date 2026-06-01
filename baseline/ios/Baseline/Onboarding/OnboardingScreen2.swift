import SwiftUI

struct OnboardingScreen2: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @AppStorage("baseline.userName") private var storedUserName: String = ""
    @State private var name: String = ""
    @FocusState private var isFocused: Bool
    @State private var focusWorkItem: DispatchWorkItem?

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canContinue: Bool {
        !trimmedName.isEmpty
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

                        Text("Your coach will speak to you directly.")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .padding(.top, 16)

                        nameField
                            .padding(.top, 40)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            if name.isEmpty, !storedUserName.isEmpty {
                name = storedUserName
            }
            scheduleFocus()
        }
        .onDisappear {
            focusWorkItem?.cancel()
            focusWorkItem = nil
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 0)

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
            Text("What should we call ")
                .foregroundStyle(Color.white)
            + Text("you")
                .foregroundStyle(Color(hex: "#8B7DFF"))
            + Text("?")
                .foregroundStyle(Color.white)
        )
        .font(.system(size: 32, weight: .light, design: .serif))
        .fixedSize(horizontal: false, vertical: true)
    }

    private var nameField: some View {
        TextField(
            "",
            text: $name,
            prompt: Text("Your name")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Color(hex: "#444444")),
        )
        .font(.system(size: 17, weight: .light))
        .foregroundStyle(Color.white)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .keyboardType(.namePhonePad)
        .focused($isFocused)
        .padding(.horizontal, 16)
        .frame(height: 52)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(
                    isFocused ? Color(hex: "#8B7DFF") : Color(hex: "#2A2A2A"),
                    lineWidth: 1,
                ),
        )
    }

    private var continueButton: some View {
        Button {
            let trimmed = trimmedName
            storedUserName = trimmed
            onboarding.setPreferredName(trimmed)
            onNext()
        } label: {
            Text("Continue →")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(canContinue ? Color.white : Color(hex: "#333333"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(canContinue ? Color(hex: "#7C5CBF") : Color(hex: "#1A1A1A"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canContinue)
        .animation(.easeInOut(duration: 0.2), value: canContinue)
    }

    // MARK: - Focus

    private func scheduleFocus() {
        focusWorkItem?.cancel()
        let item = DispatchWorkItem {
            isFocused = true
        }
        focusWorkItem = item
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3, execute: item)
    }
}
