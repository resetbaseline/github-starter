import SwiftUI
import UIKit

struct TimersView: View {
    @StateObject private var viewModel = TimersViewModel()
    @State private var livePulse = false

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header

                ScrollView {
                    VStack(spacing: 16) {
                        focusTimerCard
                        if showsBlockedApps {
                            blockedAppsRow
                        }
                        if showsDebrief {
                            debriefCard
                        }
                        todaysFocusRow
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
            }
        }
        .background(Theme.Colors.background)
    }

    private var header: some View {
        Text("Focus")
            .font(.system(size: 17, weight: .light))
            .foregroundStyle(Theme.Colors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 8)
            .background(Theme.Colors.background)
    }

    private var focusTimerCard: some View {
        VStack(spacing: 14) {
            HStack {
                Text("FOCUS SESSION")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#3A2A55"))
                    .tracking(1.2)
                    .textCase(.uppercase)
                Spacer(minLength: 0)
                if viewModel.timerState == .running {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.red.opacity(0.8))
                            .frame(width: 6, height: 6)
                            .opacity(livePulse ? 1 : 0.35)
                            .animation(
                                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                                value: livePulse,
                            )
                        Text("Live")
                            .font(.system(size: 9))
                            .foregroundStyle(Color(hex: "#AA4444"))
                    }
                    .onAppear { livePulse = true }
                    .onDisappear { livePulse = false }
                }
            }

            timerRing

            presetRow

            customRotatorRow

            hardLockRow

            actionButton
        }
        .padding(16)
        .background(Color(hex: "#0A0612"))
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color(hex: "#1A1030"), lineWidth: 1),
        )
    }

    private var timerRing: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#1E1E1E"), lineWidth: 3)
                .frame(width: 160, height: 160)

            Circle()
                .trim(from: 0, to: viewModel.progressFraction)
                .stroke(
                    Theme.Colors.accent,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round),
                )
                .rotationEffect(.degrees(-90))
                .frame(width: 160, height: 160)
                .animation(.linear(duration: 1), value: viewModel.progressFraction)

            VStack(spacing: 4) {
                Text(viewModel.formattedTime)
                    .font(.system(size: 42, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text(timerStateLabel)
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#555555"))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 4)
    }

    private var timerStateLabel: String {
        switch viewModel.timerState {
        case .idle: "tap to begin"
        case .running: "focusing"
        case .paused: "paused"
        case .completed: "complete"
        }
    }

    private var presetRow: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.presetDurations, id: \.self) { duration in
                let isSelected = viewModel.selectedDuration == duration
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    viewModel.selectPreset(duration)
                } label: {
                    Text("\(duration) min")
                        .font(.system(size: 10))
                        .foregroundStyle(isSelected ? Color.white : Color(hex: "#666666"))
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(isSelected ? Color(hex: "#1A1228") : Color(hex: "#111111"))
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .stroke(
                                    isSelected ? Theme.Colors.accent : Color(hex: "#1E1E1E"),
                                    lineWidth: 1,
                                ),
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.timerState != .idle && viewModel.timerState != .paused)
            }
        }
    }

    private var customRotatorRow: some View {
        HStack {
            Text("Custom")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#555555"))
            Spacer(minLength: 0)
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.adjustCustom(-5)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.timerState == .running || viewModel.timerState == .completed)

            Text("\(viewModel.customMinutes) min")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(minWidth: 52)
                .multilineTextAlignment(.center)

            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                viewModel.adjustCustom(5)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Theme.Colors.accent)
            }
            .buttonStyle(.plain)
            .disabled(viewModel.timerState == .running || viewModel.timerState == .completed)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
        )
    }

    private var hardLockRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Hard lock")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("Cannot end session early")
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.textMuted)
            }
            Spacer(minLength: 0)
            Toggle("", isOn: $viewModel.hardLockActive)
                .tint(Theme.Colors.accent)
                .labelsHidden()
                .onChange(of: viewModel.hardLockActive) { _, _ in
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }
        }
    }

    @ViewBuilder
    private var actionButton: some View {
        switch viewModel.timerState {
        case .idle:
            BaselineButton(title: "Begin focus") {
                viewModel.startSession()
            }
        case .running:
            Button {
                viewModel.endSession()
            } label: {
                Text("End session")
                    .font(.system(size: 11))
                    .foregroundStyle(Theme.Colors.accent)
                    .frame(maxWidth: .infinity)
                    .padding(14)
                    .background(Color(hex: "#111111"))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                    )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.hardLockActive)
            .opacity(viewModel.hardLockActive ? 0.5 : 1)
        case .paused:
            HStack(spacing: 8) {
                Button {
                    viewModel.resumeSession()
                } label: {
                    Text("Resume")
                        .font(.system(size: 11))
                        .foregroundStyle(Color.white)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Theme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .buttonStyle(.plain)

                Button {
                    viewModel.endSession()
                } label: {
                    Text("End")
                        .font(.system(size: 11))
                        .foregroundStyle(Theme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .padding(14)
                        .background(Color(hex: "#111111"))
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                        )
                }
                .buttonStyle(.plain)
                .disabled(viewModel.hardLockActive)
                .opacity(viewModel.hardLockActive ? 0.5 : 1)
            }
        case .completed:
            BaselineButton(title: "Done") {
                viewModel.resetAfterComplete()
            }
        }
    }

    private var showsBlockedApps: Bool {
        viewModel.timerState == .running || viewModel.timerState == .paused
    }

    private var showsDebrief: Bool {
        viewModel.timerState == .completed && !viewModel.debriefText.isEmpty
    }

    private var blockedAppsRow: some View {
        HStack(spacing: 6) {
            Text("Blocking")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#3A3A3A"))
            ForEach(viewModel.blockedApps) { app in
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color(hex: app.colorHex))
                        .frame(width: 10, height: 10)
                    Text(app.name)
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#555555"))
                }
                .padding(.vertical, 3)
                .padding(.horizontal, 7)
                .background(Color(hex: "#0D0D0D"))
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
                )
            }
            Spacer(minLength: 0)
        }
    }

    private var debriefCard: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("COACH NOTE")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#4A3880"))
                .tracking(1.2)
                .textCase(.uppercase)
            Text(viewModel.debriefText)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#9B7FD4"))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(EdgeInsets(top: 10, leading: 12, bottom: 10, trailing: 12))
        .background(Color(hex: "#0F0828"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
        )
    }

    private var todaysFocusRow: some View {
        HStack {
            Text("Today's focus")
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#555555"))
            Spacer(minLength: 0)
            Text("\(viewModel.focusMinutesLoggedToday) min logged")
                .font(.system(size: 10))
                .foregroundStyle(Theme.Colors.accent)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .background(Color(hex: "#111111"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "#1E1E1E"), lineWidth: 1),
        )
    }
}
