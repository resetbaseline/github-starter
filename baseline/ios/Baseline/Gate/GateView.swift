import SwiftUI

struct GateView: View {
    @EnvironmentObject private var viewModel: GateViewModel

    private let glowAccent = Color(red: 124 / 255, green: 92 / 255, blue: 191 / 255)

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

            ScrollView {
                VStack(spacing: 0) {
                    topSection
                    reasonsGrid
                    if viewModel.selectedReason != nil {
                        coachCard
                    }
                    bottomActions
                }
                .padding(.top, 36)
            }

            VStack {
                HStack {
                    Spacer(minLength: 0)
                    Button {
                        viewModel.closeGate()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color(hex: "#666666"))
                            .padding(8)
                    }
                    .buttonStyle(.plain)
                    .padding(20)
                }
                Spacer(minLength: 0)
            }
        }
        .onAppear {
            viewModel.resetGate()
        }
    }

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

    private var coachCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .center, spacing: 8) {
                CoachPeakIcon(size: 18)
                Text("COACH")
                    .font(.system(size: 8))
                    .foregroundStyle(Color(hex: "#4A3880"))
                    .tracking(1.2)
                    .textCase(.uppercase)
            }

            Text(viewModel.coachResponse)
                .font(.system(size: 10))
                .foregroundStyle(Color(hex: "#9B7FD4"))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(hex: "#0F0828"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#2D1F4A"), lineWidth: 1),
        )
        .padding(.horizontal, 28)
        .padding(.top, 16)
    }

    private var bottomActions: some View {
        VStack(spacing: 10) {
            if viewModel.selectedReason == .genuineNeed {
                BaselineButton(title: "Let me through") {
                    viewModel.letMeThrough()
                }
                Button("Actually, close it") {
                    viewModel.closeGate()
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#555555"))
                .buttonStyle(.plain)
            } else if viewModel.selectedReason != nil {
                BaselineButton(title: "Close the app") {
                    viewModel.closeGate()
                }
                Button("Let me through anyway") {
                    viewModel.letMeThrough()
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#3A3A3A"))
                .buttonStyle(.plain)
            } else {
                Button("Close") {
                    viewModel.closeGate()
                }
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "#3A3A3A"))
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 28)
        .padding(.top, 24)
        .padding(.bottom, 40)
    }
}
