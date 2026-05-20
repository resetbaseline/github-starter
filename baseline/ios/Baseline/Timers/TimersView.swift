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

            customDialSection

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

    private var customDialSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Custom duration")
                    .font(.system(size: 10))
                    .foregroundStyle(Color(hex: "#555555"))
                Spacer(minLength: 0)
                if viewModel.selectedDuration == viewModel.customMinutes {
                    Text("selected")
                        .font(.system(size: 9))
                        .foregroundStyle(Theme.Colors.accent)
                }
            }

            DialTimerPicker(
                minutes: $viewModel.customMinutes,
                disabled: viewModel.timerState == .running || viewModel.timerState == .completed,
                onSelect: { viewModel.selectCustom() },
            )
            .frame(maxWidth: .infinity)
            .onChange(of: viewModel.customMinutes) { _, _ in
                viewModel.adjustCustom(0)
            }
        }
        .padding(14)
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

// MARK: - Dial picker

private struct DialTimerPicker: View {
    @Binding var minutes: Int
    let range: ClosedRange<Int> = 1 ... 180
    let disabled: Bool
    var onSelect: () -> Void = {}

    @State private var isDragging = false

    private let diameter: CGFloat = 160
    private let radius: CGFloat = 72

    private var progressFraction: Double {
        Double(minutes - range.lowerBound) / Double(range.upperBound - range.lowerBound)
    }

    private var handleAngle: Double {
        progressFraction * 2 * .pi - .pi / 2
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 1.5)

            ForEach(0 ..< 12, id: \.self) { index in
                tickMark(at: index)
            }

            Circle()
                .trim(from: 0, to: progressFraction)
                .stroke(
                    Theme.Colors.accent,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round),
                )
                .rotationEffect(.degrees(-90))

            Circle()
                .fill(Theme.Colors.accent)
                .frame(width: 14, height: 14)
                .scaleEffect(isDragging ? 1.2 : 1)
                .animation(.spring(response: 0.2), value: isDragging)
                .offset(
                    x: CGFloat(cos(handleAngle)) * radius,
                    y: CGFloat(sin(handleAngle)) * radius,
                )

            VStack(spacing: 2) {
                Text("\(minutes)")
                    .font(.system(size: 32, weight: .ultraLight, design: .monospaced))
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("min")
                    .font(.system(size: 9))
                    .foregroundStyle(Color(hex: "#555555"))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }
        }
        .frame(width: diameter, height: diameter)
        .opacity(disabled ? 0.5 : 1)
        .contentShape(Circle())
        .gesture(dragGesture)
        .onTapGesture {
            if !disabled {
                onSelect()
            }
        }
        .allowsHitTesting(!disabled)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { value in
                guard !disabled else { return }
                isDragging = true
                let center = CGPoint(x: diameter / 2, y: diameter / 2)
                let dx = value.location.x - center.x
                let dy = value.location.y - center.y
                let angle = atan2(dy, dx)
                var normalized = angle + .pi / 2
                if normalized < 0 {
                    normalized += 2 * .pi
                }
                var newMinutes = Int(normalized / (2 * .pi) * Double(range.upperBound)) + 1
                newMinutes = min(range.upperBound, max(range.lowerBound, newMinutes))

                if newMinutes != minutes {
                    let stepDelta = abs(newMinutes - minutes)
                    for _ in 0 ..< stepDelta {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    }
                    minutes = newMinutes
                }
            }
            .onEnded { _ in
                isDragging = false
            }
    }

    private func tickMark(at index: Int) -> some View {
        let degrees = Double(index) * 30 - 90
        let radians = degrees * .pi / 180
        let innerRadius = radius - 6
        let center = diameter / 2

        return Path { path in
            path.move(
                to: CGPoint(
                    x: center + CGFloat(cos(radians)) * innerRadius,
                    y: center + CGFloat(sin(radians)) * innerRadius,
                ),
            )
            path.addLine(
                to: CGPoint(
                    x: center + CGFloat(cos(radians)) * radius,
                    y: center + CGFloat(sin(radians)) * radius,
                ),
            )
        }
        .stroke(Color(hex: "#2A2A2A"), lineWidth: 1)
    }
}
