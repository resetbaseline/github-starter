import SwiftUI

struct OnboardingSetupView: View {
    @EnvironmentObject private var auth: AuthManager
    @EnvironmentObject private var onboarding: OnboardingViewModel
    @State private var displayName: String = ""
    @State private var showNameError = false
    @State private var wakeTime =
        Calendar.current.date(bySettingHour: 7, minute: 0, second: 0, of: Date()) ?? Date()
    @State private var checkInTime =
        Calendar.current.date(bySettingHour: 21, minute: 0, second: 0, of: Date()) ?? Date()

    private var trimmedName: String {
        displayName.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var nameIsReady: Bool {
        !trimmedName.isEmpty
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.lg) {
                Text(OnboardingViewModel.stepLabel(forStaticPage: 4))
                    .font(Theme.Typography.caption1())
                    .foregroundStyle(Theme.Colors.textMuted)

                Text("Almost there")
                    .font(Theme.Typography.title1())
                    .foregroundStyle(Theme.Colors.textPrimary)

                Text("We’ll use this for greetings in the app. You can change it later in Profile.")
                    .font(Theme.Typography.body())
                    .foregroundStyle(Theme.Colors.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("What should we call you?")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)

                    TextField("Your name", text: $displayName)
                        .font(Theme.Typography.body())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .padding(Theme.Spacing.sm)
                        .background(Theme.Colors.surface)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                                .stroke(Theme.Colors.border, lineWidth: 1)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                        .onChange(of: displayName) { _, _ in
                            if nameIsReady {
                                showNameError = false
                            }
                        }

                    if showNameError {
                        Text("We need something to call you")
                            .font(Theme.Typography.caption1())
                            .foregroundStyle(Theme.Colors.textMuted)
                    }
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("Time zone")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    Text(TimeZone.current.identifier)
                        .font(Theme.Typography.callout())
                        .foregroundStyle(Theme.Colors.textPrimary)
                    Text("Schedules and day boundaries follow your device time zone. You can adjust in Profile when travel mode ships.")
                        .font(Theme.Typography.footnote())
                        .foregroundStyle(Theme.Colors.textMuted)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("When do you start your day?")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    DatePicker("", selection: $wakeTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
                    Text("When do you want to close it?")
                        .font(Theme.Typography.subheadline())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    DatePicker("", selection: $checkInTime, displayedComponents: .hourAndMinute)
                        .datePickerStyle(.wheel)
                        .labelsHidden()
                }

                Button(action: attemptGetStarted) {
                    Text("Get started")
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Theme.Spacing.sm)
                        .background(Theme.Colors.accent)
                        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
                }
                .buttonStyle(.plain)
                .opacity(nameIsReady ? 1 : 0.4)
                .padding(.top, Theme.Spacing.sm)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.Spacing.md)
            .padding(.top, Theme.Spacing.lg)
            .padding(.bottom, Theme.Spacing.xl)
        }
    }

    private func attemptGetStarted() {
        guard nameIsReady else {
            showNameError = true
            return
        }
        auth.completeOnboarding(
            preferredName: trimmedName,
            wakeTime: wakeTime,
            checkInTime: checkInTime,
            longTermGoals: onboarding.longTermGoalDrafts,
        )
    }
}
