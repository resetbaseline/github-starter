import SwiftUI
import UIKit

struct OnboardingScreen9: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var selectedAreas: Set<String> = []

    private let lifeAreas: [(label: String, symbol: String)] = [
        ("Health & Fitness", "heart"),
        ("Career & Work", "briefcase"),
        ("Finances", "dollarsign.circle"),
        ("Relationships", "person.2"),
        ("Mental Wellbeing", "brain.head.profile"),
        ("Learning & Skills", "book"),
        ("Creative Work", "paintbrush"),
        ("Lifestyle & Habits", "moon.stars"),
        ("Other", "plus"),
    ]

    private var displayYears: Double {
        onboarding.yearsOnPhone > 0 ? onboarding.yearsOnPhone : 5.8
    }

    private var canContinue: Bool {
        !selectedAreas.isEmpty
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
                        yearsCallback
                            .padding(.top, 32)

                        headline
                            .padding(.top, 8)

                        Text("Add more or edit anytime — no need to get it perfect now.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#3A3A3A"))
                            .fixedSize(horizontal: false, vertical: true)
                            .padding(.top, 10)
                            .padding(.horizontal, 32)

                        chipGrid
                            .padding(.top, 28)
                            .padding(.horizontal, 32)

                        Text("Your coach will remember what you're building toward.")
                            .font(.system(size: 13, weight: .light))
                            .foregroundStyle(Color(hex: "#555555"))
                            .padding(.top, 16)
                            .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, 16)
                }
                .scrollDismissesKeyboard(.interactively)

                continueButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: selectedAreas.isEmpty)
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 2)

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

    private var yearsCallback: some View {
        (
            Text("That's ")
                .font(.system(size: 18, weight: .light))
            + Text("\(String(format: "%.1f", displayYears)) years")
                .font(.system(size: 18, weight: .semibold))
            + Text(" you get back.")
                .font(.system(size: 18, weight: .light))
        )
        .foregroundStyle(Color(hex: "#8B7DFF"))
        .padding(.horizontal, 32)
    }

    private var headline: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Where do you want")
                .foregroundStyle(Color.white)
            Text("to level up?")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        }
        .font(.system(size: 36, weight: .light, design: .serif))
        .padding(.horizontal, 32)
    }

    private var chipGrid: some View {
        VStack(spacing: 10) {
            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 10),
                    GridItem(.flexible(), spacing: 10),
                ],
                spacing: 10,
            ) {
                ForEach(lifeAreas.prefix(8), id: \.label) { area in
                    areaChip(area)
                }
            }

            HStack(spacing: 10) {
                if let other = lifeAreas.last {
                    areaChip(other)
                }
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .accessibilityHidden(true)
            }
        }
    }

    private func areaChip(_ area: (label: String, symbol: String)) -> some View {
        let isSelected = selectedAreas.contains(area.label)

        return Button {
            toggleArea(area.label)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: Self.resolvedSymbol(area.symbol))
                    .font(.system(size: 16, weight: .thin))
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "#888888"))

                Text(area.label)
                    .font(.system(size: 15, weight: .light))
                    .foregroundStyle(isSelected ? Color.white : Color(hex: "#888888"))
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 44)
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
            onboarding.setLifeAreas(
                areas: Array(selectedAreas),
                description: "",
            )
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

    private func toggleArea(_ label: String) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedAreas.contains(label) {
                selectedAreas.remove(label)
            } else {
                selectedAreas.insert(label)
            }
        }
    }

    private static func resolvedSymbol(_ symbol: String) -> String {
        if symbol == "brain.head.profile", UIImage(systemName: "brain.head.profile") == nil {
            return "brain"
        }
        return symbol
    }
}
