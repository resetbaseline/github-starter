import SwiftUI

struct OnboardingScreen6: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var age: String = ""
    @State private var dailyHours: Double = 4.0
    @State private var hasMovedSlider: Bool = false
    @State private var shakeOffset: CGFloat = 0
    @State private var pulseScale: CGFloat = 1.0
    @FocusState private var ageFieldFocused: Bool

    private var isValid: Bool {
        guard let ageInt = Int(age) else { return false }
        return ageInt >= 13 && ageInt <= 100 && hasMovedSlider
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
                    VStack(spacing: 0) {
                        headlineBlock

                        ageSection
                            .padding(.top, 32)

                        divider
                            .padding(.top, 28)

                        phoneSection
                            .padding(.top, 24)

                        hoursDisplay
                            .padding(.top, 20)

                        Text("Be honest. This is just for you.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
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

    // MARK: - Headline

    private var headlineBlock: some View {
        VStack(alignment: .leading, spacing: 0) {
            headline
                .padding(.top, 48)

            Text("Two quick things before we show you your number.")
                .font(.system(size: 15, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .padding(.top, 12)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var headline: some View {
        (
            Text("First, let's be honest\n")
                .foregroundStyle(Color.white)
            + Text("about your time.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
    }

    // MARK: - Age

    private var ageSection: some View {
        VStack(spacing: 8) {
            Text("Your age")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#888888"))

            TextField(
                "",
                text: $age,
                prompt: Text("––")
                    .font(.system(size: 24, weight: .light))
                    .foregroundStyle(Color(hex: "#333333")),
            )
            .font(.system(size: 24, weight: .light))
            .foregroundStyle(Color.white)
            .multilineTextAlignment(.center)
            .keyboardType(.numberPad)
            .focused($ageFieldFocused)
            .frame(width: 140, height: 52)
            .background(Color(hex: "#111111"))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(
                        ageFieldFocused ? Color(hex: "#8B7DFF") : Color(hex: "#2A2A2A"),
                        lineWidth: 1,
                    ),
            )
            .offset(x: shakeOffset)
            .onChange(of: age) { _, newValue in
                age = String(newValue.filter(\.isNumber).prefix(3))
            }
            .onChange(of: ageFieldFocused) { _, isFocused in
                if !isFocused {
                    validateAgeOnBlur()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(Color(hex: "#1E1E1E"))
            .frame(height: 1)
            .padding(.horizontal, 32)
    }

    // MARK: - Phone usage

    private var phoneSection: some View {
        VStack(spacing: 20) {
            Text("How much time do you spend on your phone each day?")
                .font(.system(size: 16, weight: .light))
                .foregroundStyle(Color.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(spacing: 8) {
                Slider(value: $dailyHours, in: 1 ... 12, step: 1)
                    .tint(Color(hex: "#7C5CBF"))
                    .padding(.horizontal, 32)
                    .onChange(of: dailyHours) { _, _ in
                        hasMovedSlider = true
                        withAnimation(.easeInOut(duration: 0.1)) {
                            pulseScale = 1.05
                        }
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                            withAnimation(.easeInOut(duration: 0.1)) {
                                pulseScale = 1.0
                            }
                        }
                    }

                HStack {
                    Text("1")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color(hex: "#444444"))
                    Spacer()
                    Text("12")
                        .font(.system(size: 12, weight: .light))
                        .foregroundStyle(Color(hex: "#444444"))
                }
                .padding(.horizontal, 32)
            }
        }
    }

    private var hoursDisplay: some View {
        VStack(spacing: 4) {
            Text("\(Int(dailyHours))")
                .font(.system(size: 72, weight: .light))
                .foregroundStyle(Color(hex: "#8B7DFF"))
                .scaleEffect(pulseScale)

            Text("hours")
                .font(.system(size: 20, weight: .light))
                .foregroundStyle(Color(hex: "#8B7DFF"))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Continue

    private var continueButton: some View {
        Button {
            let ageInt = Int(age) ?? 22
            let yearsRemaining = Double(80 - ageInt)
            let yearsOnPhone = (dailyHours * 365 * yearsRemaining) / 8760
            onboarding.setTimeEstimate(
                age: ageInt,
                dailyHours: dailyHours,
                yearsOnPhone: yearsOnPhone,
            )
            onNext()
        } label: {
            Text("Continue →")
                .font(.system(size: 17, weight: .regular))
                .foregroundStyle(isValid ? Color.white : Color(hex: "#333333"))
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isValid ? Color(hex: "#7C5CBF") : Color(hex: "#1A1A1A"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .stroke(
                            isValid ? Color.clear : Color(hex: "#2A2A2A"),
                            lineWidth: 1,
                        ),
                )
        }
        .buttonStyle(.plain)
        .disabled(!isValid)
        .animation(.easeInOut(duration: 0.2), value: isValid)
    }

    // MARK: - Validation

    private func validateAgeOnBlur() {
        guard !age.isEmpty else { return }
        guard let ageInt = Int(age), ageInt >= 13, ageInt <= 100 else {
            shakeField()
        }
    }

    private func shakeField() {
        let shakeSequence: [CGFloat] = [-8, 8, -6, 6, -4, 4, 0]
        for (index, offset) in shakeSequence.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 0.05) {
                withAnimation(.easeInOut(duration: 0.05)) {
                    shakeOffset = offset
                }
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            age = ""
        }
    }
}
