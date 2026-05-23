import SwiftUI

struct GateView: View {
    @EnvironmentObject private var viewModel: GateViewModel
    @State private var showEmergencyExitAlert = false
    @FocusState private var responseFieldFocused: Bool

    private let glowAccent = Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255)

    private var isConversationPhase: Bool {
        switch viewModel.conversationStep {
        case .reasonPicking, .openAnyway:
            false
        case .coachChallenge, .coachSecondChallenge, .validated:
            true
        }
    }

    var body: some View {
        ZStack {
            Color(hex: "#07040F")
                .ignoresSafeArea()

            RadialGradient(
                colors: [
                    glowAccent.opacity(0.15),
                    Color.clear,
                ],
                center: UnitPoint(x: 0.5, y: 0),
                startRadius: 0,
                endRadius: 420,
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 0) {
                        if viewModel.conversationStep == .reasonPicking {
                            topSection
                                .transition(.move(edge: .top).combined(with: .opacity))
                        }

                        Group {
                            if viewModel.conversationStep == .reasonPicking {
                                reasonPickingPhase
                                    .transition(.move(edge: .top).combined(with: .opacity))
                            } else if isConversationPhase {
                                conversationPhase
                                    .transition(.move(edge: .bottom).combined(with: .opacity))
                            }
                        }
                    }
                    .padding(.top, 36)
                    .animation(.easeInOut(duration: 0.3), value: viewModel.conversationStep)
                }

                emergencyExitFooter
            }
        }
        .onAppear {
            viewModel.resetGate()
        }
        .alert("Use emergency exit?", isPresented: $showEmergencyExitAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Use exit", role: .destructive) {
                viewModel.useEmergencyExit()
            }
        } message: {
            Text(
                "This uses one of your \(viewModel.emergencyExitsRemaining) emergency exits. The app will open for 30 minutes.",
            )
        }
    }

    // MARK: - Phase 1

    private var reasonPickingPhase: some View {
        VStack(spacing: 0) {
            reasonsGrid

            if viewModel.selectedReason == .other {
                otherReasonField
                    .padding(.horizontal, 28)
                    .padding(.top, 10)
                    .onChange(of: viewModel.otherReason) { _, _ in
                        viewModel.advanceFromOtherReasonIfReady()
                    }
            }

            Button("Close") {
                viewModel.closeGate()
            }
            .font(.system(size: 11))
            .foregroundStyle(Color(hex: "#3A3A3A"))
            .buttonStyle(.plain)
            .frame(maxWidth: .infinity)
            .padding(.top, 28)
            .padding(.bottom, 16)
        }
    }

    private var otherReasonField: some View {
        TextField("What's going on?", text: $viewModel.otherReason, axis: .vertical)
            .font(.system(size: 13))
            .foregroundStyle(Theme.Colors.textPrimary)
            .lineLimit(3 ... 6)
            .padding(12)
            .background(Color(hex: "#0F0F0F"))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
            )
    }

    // MARK: - Phase 2 & 3

    private var conversationPhase: some View {
        VStack(spacing: 0) {
            selectedReasonRecap
                .padding(.horizontal, 28)
                .padding(.top, 52)
                .padding(.bottom, 16)

            conversationThread
                .padding(.horizontal, 20)

            if viewModel.conversationStep == .validated {
                validatedActions
            } else {
                challengeInputSection
            }
        }
        .padding(.bottom, 8)
    }

    private var selectedReasonRecap: some View {
        Group {
            if let reason = viewModel.selectedReason {
                HStack(spacing: 8) {
                    Text(reason.displayName)
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.accent)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(Color(hex: "#1A1228"))
                        .clipShape(Capsule())
                        .overlay(
                            Capsule()
                                .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                        )

                    if reason == .other, !viewModel.otherReason.isEmpty {
                        Text(viewModel.otherReason)
                            .font(.system(size: 10))
                            .foregroundStyle(Color(hex: "#666666"))
                            .lineLimit(2)
                    }

                    Spacer(minLength: 0)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var conversationThread: some View {
        VStack(alignment: .leading, spacing: 12) {
            GateCoachBubble(text: viewModel.coachChallenge)

            if !viewModel.userResponse.isEmpty {
                GateUserBubble(text: viewModel.userResponse)
            }

            if viewModel.conversationStep == .coachSecondChallenge {
                GateCoachBubble(text: viewModel.coachSecondChallenge)
            }

            if viewModel.conversationStep == .validated, !viewModel.isValidated {
                GateCoachBubble(text: viewModel.coachSecondChallenge)
                if !viewModel.secondUserResponse.isEmpty {
                    GateUserBubble(text: viewModel.secondUserResponse)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var challengeInputSection: some View {
        VStack(spacing: 10) {
            responseInputRow
                .padding(.horizontal, 20)
                .padding(.top, 20)

            Button("Open anyway") {
                viewModel.openAnyway()
            }
            .font(.system(size: 11))
            .foregroundStyle(Color(hex: "#3A3A3A"))
            .buttonStyle(.plain)
            .padding(.bottom, 8)
        }
    }

    private var responseInputRow: some View {
        let isSecond = viewModel.conversationStep == .coachSecondChallenge
        let binding = isSecond ? $viewModel.secondUserResponse : $viewModel.userResponse
        let trimmedEmpty = (isSecond ? viewModel.secondUserResponse : viewModel.userResponse)
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        return HStack(spacing: 10) {
            TextField("Type your answer...", text: binding, axis: .vertical)
                .font(.system(size: 13))
                .foregroundStyle(Theme.Colors.textPrimary)
                .lineLimit(1 ... 4)
                .focused($responseFieldFocused)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color(hex: "#0F0F0F"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                )

            Button {
                if isSecond {
                    viewModel.submitSecondResponse()
                } else {
                    viewModel.submitUserResponse()
                }
            } label: {
                Image(systemName: "paperplane.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.white)
                    .frame(width: 26, height: 26)
                    .background(Theme.Colors.accent)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
            .disabled(trimmedEmpty)
            .opacity(trimmedEmpty ? 0.5 : 1)
        }
    }

    private var validatedActions: some View {
        VStack(spacing: 12) {
            Text("✓ Reason accepted")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#4A9A4A"))
                .frame(maxWidth: .infinity)
                .padding(EdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12))
                .background(Color(hex: "#0A1A0A"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(Color(hex: "#1A4A1A"), lineWidth: 1),
                )
                .padding(.horizontal, 28)
                .padding(.top, 20)

            BaselineButton(title: "Open \(viewModel.blockedAppName) (5 min)") {
                viewModel.letMeThrough()
            }
            .padding(.horizontal, 28)
            .padding(.bottom, 8)
        }
    }

    // MARK: - Shared

    private var topSection: some View {
        VStack(spacing: 0) {
            Text(viewModel.blockedAppName)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#7C5CBF"))
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color(hex: "#1A1228"))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                )

            Color.clear
                .frame(height: 20)

            Text("Before you open it —")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .multilineTextAlignment(.center)

            Text(viewModel.intentionQuestion)
                .font(.system(size: 22, weight: .light, design: .serif))
                .foregroundStyle(Theme.Colors.textPrimary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            if viewModel.triggerCount > 0 {
                Text("You've opened \(viewModel.blockedAppName) \(viewModel.triggerCount) times today.")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#3A3A3A"))
                    .multilineTextAlignment(.center)
                    .padding(.top, 12)
            }
        }
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 28)
        .padding(.top, 52)
        .padding(.bottom, 8)
    }

    private var reasonsGrid: some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
            ],
            spacing: 8,
        ) {
            ForEach(GateReason.allCases) { reason in
                reasonCell(reason)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
    }

    private func reasonCell(_ reason: GateReason) -> some View {
        let selected = viewModel.selectedReason == reason
        return Button {
            viewModel.selectReason(reason)
        } label: {
            Text(reason.displayName)
                .font(.system(size: 12))
                .foregroundStyle(selected ? Color.white : Color(hex: "#666666"))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(selected ? Color(hex: "#1A1228") : Color(hex: "#0F0F0F"))
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(selected ? Theme.Colors.accent : Color(hex: "#1E1E1E"), lineWidth: 1),
                )
        }
        .buttonStyle(.plain)
    }

    private var emergencyExitFooter: some View {
        VStack(spacing: 4) {
            if viewModel.emergencyExitsRemaining > 0 {
                Button {
                    showEmergencyExitAlert = true
                } label: {
                    Text("Emergency exit (\(viewModel.emergencyExitsRemaining) left)")
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#2A2A2A"))
                }
                .buttonStyle(.plain)
                .disabled(viewModel.emergencyExitsRemaining == 0)
            } else {
                Text("No emergency exits remaining this month")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#333333"))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .padding(.horizontal, 28)
        .background(Color(hex: "#07040F"))
    }
}

// MARK: - Chat bubbles (Gate)

private struct GateCoachBubble: View {
    let text: String

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.85
    }

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            CoachPeakIcon(size: 20)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 3) {
                Text("COACH")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#4A3880"))
                    .tracking(1.2)
                    .textCase(.uppercase)

                Text(text)
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#9B7FD4"))
                    .lineSpacing(5)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
            .frame(maxWidth: maxWidth, alignment: .leading)
            .background(Color(hex: "#0A0614"))
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12,
                    style: .continuous,
                ),
            )
            .overlay(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: 4,
                    bottomTrailingRadius: 12,
                    topTrailingRadius: 12,
                    style: .continuous,
                )
                .stroke(Color(hex: "#1A1030"), lineWidth: 1),
            )

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct GateUserBubble: View {
    let text: String

    private var maxWidth: CGFloat {
        UIScreen.main.bounds.width * 0.80
    }

    var body: some View {
        HStack {
            Spacer(minLength: 0)
            Text(text)
                .font(.system(size: 10))
                .foregroundStyle(Color.white)
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
                .padding(EdgeInsets(top: 8, leading: 11, bottom: 8, trailing: 11))
                .frame(maxWidth: maxWidth, alignment: .trailing)
                .background(Color(hex: "#1A1228"))
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 12,
                        style: .continuous,
                    ),
                )
                .overlay(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 4,
                        topTrailingRadius: 12,
                        style: .continuous,
                    )
                    .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                )
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}
