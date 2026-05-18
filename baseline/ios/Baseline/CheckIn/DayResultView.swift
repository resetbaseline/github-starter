import SwiftUI

struct DayResultView: View {
    @EnvironmentObject private var viewModel: CheckInViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                ResultProgressBarView()

                Text(viewModel.dayStatusHeadline + ".")
                    .font(.system(size: 20, weight: .light, design: .serif))
                    .foregroundStyle(Theme.Colors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)

                Text(viewModel.dayStatusBody)
                    .font(.system(size: 9))
                    .foregroundStyle(Theme.Colors.textMuted)
                    .fixedSize(horizontal: false, vertical: true)

                HStack(spacing: 5) {
                    statCard(
                        value: "\(viewModel.nonNegotiableCompletedCount)/\(viewModel.nonNegotiableTotalCount)",
                        label: "Non-neg.",
                    )
                    statCard(
                        value: "\(viewModel.focusMinutesTotal)m",
                        label: "Focus",
                    )
                    statCard(
                        value: "\(viewModel.reflectionAnswerCount)",
                        label: "Reflections",
                    )
                }

                StreakRevealView(
                    streakBefore: viewModel.streakBefore,
                    streakAfter: viewModel.streakAfter,
                )
                .id(viewModel.streakAfter)

                VStack(alignment: .leading, spacing: 6) {
                    Text("COACH NOTE")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#4A3880"))
                        .tracking(1.2)
                        .textCase(.uppercase)
                    Text(viewModel.coachNotePreview)
                        .font(.system(size: 9))
                        .foregroundStyle(Color(hex: "#9B7FD4"))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.vertical, 7)
                .padding(.horizontal, 9)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(hex: "#0F0828"))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
                )

                if viewModel.computedDayStatus == "light" {
                    Toggle(isOn: Binding(
                        get: { viewModel.useStreakFreeze },
                        set: { viewModel.setStreakFreeze($0) },
                    )) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Use streak freeze")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundStyle(Theme.Colors.textPrimary)
                            Text("If you have a freeze available, this keeps your current streak number instead of resetting.")
                                .font(.system(size: 11))
                                .foregroundStyle(Theme.Colors.textMuted)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .tint(Theme.Colors.accent)
                    .padding(10)
                    .background(Color(hex: "#0F0F0F"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                    )
                }

                if !viewModel.tomorrowIntention.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Tomorrow")
                            .font(.system(size: 9))
                            .foregroundStyle(Theme.Colors.textMuted)
                        Text(viewModel.tomorrowIntention)
                            .font(.system(size: 12))
                            .foregroundStyle(Theme.Colors.textPrimary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(Color(hex: "#0F0F0F"))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
                    )
                }

                BaselineButton(title: "Done") {
                    viewModel.completeCheckInAndReset()
                }
                .padding(.top, 6)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
        .background(Theme.Colors.background)
    }

    private func statCard(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)
            Text(label)
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#444444"))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .padding(.horizontal, 8)
        .background(Color(hex: "#0F0F0F"))
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .stroke(Color(hex: "#1A1A1A"), lineWidth: 1),
        )
    }
}

// MARK: - Progress (complete)

private struct ResultProgressBarView: View {
    var body: some View {
        VStack(alignment: .trailing, spacing: 6) {
            HStack(spacing: 4) {
                ForEach(0 ..< 3, id: \.self) { _ in
                    Capsule()
                        .fill(Theme.Colors.accent)
                        .frame(maxWidth: .infinity)
                        .frame(height: 2)
                }
            }
            Text("Complete")
                .font(.system(size: 8))
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
}

// MARK: - Streak reveal

private struct StreakRevealView: View {
    let streakBefore: Int
    let streakAfter: Int

    @State private var displayedStreakCount: Int = 0
    @State private var ringOpacityInner: CGFloat = 0
    @State private var ringOpacityMid: CGFloat = 0
    @State private var ringOpacityOuter: CGFloat = 0
    @State private var streakNumberColor: Color = Theme.Colors.textPrimary

    private let accentSoft = Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255)

    var body: some View {
        VStack(spacing: 0) {
            Text("YOUR BASELINE")
                .font(.system(size: 8))
                .foregroundStyle(Color(hex: "#3A2A55"))
                .tracking(1.4)
                .textCase(.uppercase)
                .padding(.bottom, 10)

            ZStack {
                Circle()
                    .stroke(accentSoft.opacity(0.1 * ringOpacityOuter), lineWidth: 1)
                    .frame(width: 72, height: 72)
                Circle()
                    .stroke(accentSoft.opacity(0.25 * ringOpacityMid), lineWidth: 1)
                    .frame(width: 54, height: 54)
                Circle()
                    .stroke(accentSoft.opacity(0.5 * ringOpacityInner), lineWidth: 1.5)
                    .frame(width: 38, height: 38)

                VStack(spacing: 2) {
                    Text("\(displayedStreakCount)")
                        .font(.system(size: 26, weight: .ultraLight))
                        .foregroundStyle(streakNumberColor)
                    Text("days")
                        .font(.system(size: 8))
                        .foregroundStyle(Color(hex: "#4A3070"))
                        .tracking(1)
                        .textCase(.uppercase)
                }
            }
            .padding(.vertical, 4)

            Text("This is what showing up looks like.")
                .font(.system(size: 9))
                .italic()
                .foregroundStyle(Color(hex: "#3A2555"))
                .padding(.top, 8)
        }
        .frame(maxWidth: .infinity)
        .padding(EdgeInsets(top: 14, leading: 10, bottom: 10, trailing: 10))
        .background(Color(hex: "#070412"))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color(hex: "#1A0F35"), lineWidth: 1),
        )
        .onAppear {
            runAnimationSequence()
        }
    }

    private func runAnimationSequence() {
        let end = streakAfter
        Task { @MainActor in
            displayedStreakCount = streakBefore
            if streakBefore == end {
                displayedStreakCount = end
            } else {
                let step = streakBefore < end ? 1 : -1
                var current = streakBefore
                while current != end {
                    try? await Task.sleep(nanoseconds: 100_000_000)
                    current += step
                    displayedStreakCount = current
                }
            }

            try? await Task.sleep(nanoseconds: 400_000_000)

            withAnimation(.easeInOut(duration: 0.6)) {
                ringOpacityInner = 1
            }
            withAnimation(.easeInOut(duration: 0.8)) {
                streakNumberColor = Color(hex: "#9B7FD4")
            }

            try? await Task.sleep(nanoseconds: 300_000_000)

            withAnimation(.easeInOut(duration: 0.8)) {
                ringOpacityMid = 1
            }

            try? await Task.sleep(nanoseconds: 600_000_000)

            withAnimation(.easeInOut(duration: 1.0)) {
                ringOpacityOuter = 1
            }
        }
    }
}
