import SwiftUI

struct OnboardingScreen4: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var selectedTimeWindow: String?

    private let timeWindows: [(label: String, symbol: String)] = [
        ("First thing in the morning", "sunrise"),
        ("During work or study", "briefcase"),
        ("Mid-afternoon slump", "moon.zzz"),
        ("Evening wind-down", "sunset"),
        ("Late night", "moon"),
        ("All day equally", "arrow.clockwise"),
    ]

    private var canContinue: Bool {
        selectedTimeWindow != nil
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

                        Text("Pick the one that hits closest.")
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .padding(.top, 16)

                        chipList
                            .padding(.top, 32)

                        Text("This helps your coach know when to protect your focus most.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .padding(.top, 20)
                    }
                    .padding(.horizontal, 32)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }

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
            Text("When do you lose\n")
                .foregroundStyle(Color.white)
            + Text("the most time?")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var chipList: some View {
        VStack(spacing: 10) {
            ForEach(timeWindows, id: \.label) { window in
                chipButton(label: window.label, symbol: window.symbol)
            }
        }
    }

    private func chipButton(label: String, symbol: String) -> some View {
        let isSelected = selectedTimeWindow == label

        return Button {
            selectTimeWindow(label)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: symbol)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 16))
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "#888888"))

                Text(label)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "#888888"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)

                Spacer(minLength: 0)

                if isSelected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 12))
                        .foregroundStyle(Color(hex: "#8B7DFF"))
                        .transition(.opacity.combined(with: .scale(scale: 0.8)))
                }
            }
            .padding(.leading, 16)
            .padding(.trailing, 16)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
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

    private var continueButton: some View {
        Button {
            onboarding.setVulnerableTimeWindow(selectedTimeWindow)
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

    private func selectTimeWindow(_ label: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            selectedTimeWindow = label
        }
    }
}
