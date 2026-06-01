import FamilyControls
import SwiftUI

struct OnboardingScreen12: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var gateEnabled = true
    @State private var selectedActivationMode = "Vulnerable windows"
    @State private var activitySelection = FamilyActivitySelection()
    @State private var selectedApps: Set<ApplicationToken> = []
    @State private var showAppPicker = false
    @State private var showPermissionDeniedAlert = false

    private let activationModes = ["Focus sessions", "Vulnerable windows", "Always"]

    private var previewGoal: String {
        onboarding.goalDetails.first?.value ?? "momentum in 6 months"
    }

    private var previewAnchor: String {
        onboarding.anchors.first?.text ?? "Finish your workout"
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

                        Text("When you drift, The Gate helps you pause before autopilot takes over.")
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                            .padding(.horizontal, 32)

                        GateMockPreview(goalText: previewGoal, anchorText: previewAnchor)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)

                        gateToggleRow
                            .padding(.top, 16)
                            .padding(.horizontal, 32)

                        activationSection
                            .padding(.top, 28)

                        blockAppsSection
                            .padding(.top, 20)

                        controlLine
                            .padding(.top, 20)
                            .padding(.horizontal, 40)
                    }
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                enableGateButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .familyActivityPicker(isPresented: $showAppPicker, selection: $activitySelection)
        .onChange(of: activitySelection) { _, newValue in
            selectedApps = newValue.applicationTokens
        }
        .alert("Screen Time Access Required", isPresented: $showPermissionDeniedAlert) {
            Button("Continue Without Gate") {
                onboarding.setGateSettings(
                    enabled: false,
                    activationMode: selectedActivationMode,
                    activitySelection: activitySelection,
                )
                onNext()
            }
            Button("Try Again") {
                handleEnableGate()
            }
        } message: {
            Text("The Gate needs Screen Time access to protect your focus. You can enable it later in Settings.")
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 3)

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
            Text("Meet\n")
                .foregroundStyle(Color.white)
            + Text("The Gate.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 32)
    }

    private var gateToggleRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "shield")
                        .font(.system(size: 18, weight: .thin))
                        .foregroundStyle(Color(hex: "#8B7DFF"))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Enable The Gate")
                            .font(.system(size: 15, weight: .regular))
                            .foregroundStyle(Color.white)
                        Text("Recommended")
                            .font(.system(size: 11, weight: .light))
                            .foregroundStyle(Color(hex: "#8B7DFF"))
                    }
                }

                Spacer(minLength: 0)

                Toggle("", isOn: $gateEnabled)
                    .labelsHidden()
                    .tint(Color(hex: "#7C5CBF"))
            }

            Text("The Gate activates during focus sessions and your vulnerable windows.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
        }
        .padding(14)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#2A2A2A"), lineWidth: 1),
        )
    }

    private var activationSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("When should The Gate activate?")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 32)

            HStack(spacing: 8) {
                ForEach(activationModes, id: \.self) { mode in
                    VStack(spacing: 3) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedActivationMode = mode
                            }
                        } label: {
                            Text(mode)
                                .font(.system(size: 13, weight: .light))
                                .foregroundStyle(
                                    selectedActivationMode == mode ? Color.white : Color(hex: "#888888"),
                                )
                                .padding(.horizontal, 16)
                                .frame(height: 36)
                                .background(
                                    selectedActivationMode == mode
                                        ? Color(hex: "#1A0D35")
                                        : Color(hex: "#161616"),
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .stroke(
                                            selectedActivationMode == mode
                                                ? Color(hex: "#8B7DFF")
                                                : Color(hex: "#2A2A2A"),
                                            lineWidth: 1,
                                        ),
                                )
                        }
                        .buttonStyle(.plain)

                        if mode == "Vulnerable windows" {
                            Text("Recommended")
                                .font(.system(size: 10, weight: .light))
                                .foregroundStyle(Color(hex: "#8B7DFF"))
                        } else {
                            Text(" ")
                                .font(.system(size: 10))
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 32)
        }
    }

    private var blockAppsSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Which apps should The Gate block?")
                .font(.system(size: 14, weight: .regular))
                .foregroundStyle(Color.white)
                .padding(.horizontal, 32)

            Button {
                showAppPicker = true
            } label: {
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "hourglass")
                            .font(.system(size: 16, weight: .thin))
                            .foregroundStyle(Color(hex: "#8B7DFF"))

                        Text(appSelectionLabel)
                            .font(.system(size: 14, weight: .light))
                            .foregroundStyle(
                                selectedApps.isEmpty ? Color(hex: "#888888") : Color.white,
                            )
                    }

                    Spacer(minLength: 0)

                    Image(systemName: "chevron.right")
                        .font(.system(size: 14))
                        .foregroundStyle(Color(hex: "#444444"))
                }
                .padding(.horizontal, 16)
                .frame(height: 52)
                .background(Color(hex: "#111111"))
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color(hex: "#2A2A2A"), lineWidth: 1),
                )
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 32)

            Text("You'll be able to change this anytime.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .padding(.horizontal, 32)
                .padding(.top, 6)
        }
    }

    private var appSelectionLabel: String {
        if selectedApps.isEmpty {
            return "Select apps to block"
        }
        return "\(selectedApps.count) apps selected"
    }

    private var controlLine: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: "person.circle")
                .font(.system(size: 12))
                .foregroundStyle(Color(hex: "#444444"))

            Text("You're always in control. The Gate adds a moment of pause — nothing more.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#444444"))
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
    }

    private var enableGateButton: some View {
        VStack(spacing: 8) {
            Button(action: handleEnableGate) {
                HStack(spacing: 6) {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 12))
                    Text("Enable The Gate →")
                        .font(.system(size: 17, weight: .regular))
                }
                .foregroundStyle(Color.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(Color(hex: "#7C5CBF"))
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
            .buttonStyle(.plain)

            Text("You'll be asked to grant Screen Time access.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Actions

    private func handleEnableGate() {
        guard gateEnabled else {
            saveGateSettings()
            onNext()
            return
        }

        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                saveGateSettings()
                onNext()
            } catch {
                showPermissionDeniedAlert = true
            }
        }
    }

    private func saveGateSettings() {
        onboarding.setGateSettings(
            enabled: gateEnabled,
            activationMode: selectedActivationMode,
            activitySelection: activitySelection,
        )
    }
}

// MARK: - Mock preview

private struct GateMockPreview: View {
    let goalText: String
    let anchorText: String

    private var coachMessage: String {
        "You said you wanted \(goalText)."
    }

    private var coachInstruction: String {
        "\(anchorText) first."
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(hex: "#0D0D0D"))
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                )
                .frame(width: 180, height: 260)

            VStack(spacing: 10) {
                HStack {
                    Text("9:41")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(Color(hex: "#555555"))
                    Spacer(minLength: 0)
                    Image(systemName: "wifi")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#555555"))
                }
                .padding(.horizontal, 14)
                .padding(.top, 8)

                VStack(spacing: 4) {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#F58529"),
                                    Color(hex: "#DD2A7B"),
                                    Color(hex: "#8134AF"),
                                ],
                                startPoint: .bottomLeading,
                                endPoint: .topTrailing,
                            ),
                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Image(systemName: "camera")
                                .font(.system(size: 14, weight: .light))
                                .foregroundStyle(Color.white),
                        )

                    Text("Instagram")
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(Color.white)
                }

                VStack(spacing: 4) {
                    Text(coachMessage)
                        .font(.system(size: 11, weight: .light))
                        .foregroundStyle(Color.white)
                        .multilineTextAlignment(.center)
                    Text(coachInstruction)
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color(hex: "#8B7DFF"))
                        .multilineTextAlignment(.center)
                }
                .padding(10)
                .background(Color(hex: "#1A0D35"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 12)

                VStack(spacing: 6) {
                    Text("Stay on Track")
                        .font(.system(size: 11, weight: .regular))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 28)
                        .background(Color(hex: "#7C5CBF"))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))

                    Text("Continue Anyway")
                        .font(.system(size: 10, weight: .light))
                        .foregroundStyle(Color(hex: "#444444"))
                }
                .padding(.horizontal, 12)

                Text("This is how The Gate will show up.")
                    .font(.system(size: 9, weight: .light))
                    .foregroundStyle(Color(hex: "#333333"))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            .frame(width: 180)
        }
    }
}
