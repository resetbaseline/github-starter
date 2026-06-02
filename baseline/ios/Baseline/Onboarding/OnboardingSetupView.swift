import SwiftUI
import UserNotifications

#if canImport(UIKit)
import UIKit
#endif

struct OnboardingSetupView: View {
    let onNext: () -> Void
    let onBack: () -> Void

    @EnvironmentObject var onboarding: OnboardingViewModel

    @State private var morningTime: Date = {
        var components = DateComponents()
        components.hour = 7
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    @State private var eveningTime: Date = {
        var components = DateComponents()
        components.hour = 21
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()

    @State private var showClosingTransition = false

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.top, 24)
                    .padding(.horizontal, 20)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 0) {
                        headline
                            .padding(.top, 32)

                        morningSection
                            .padding(.top, 28)

                        eveningSection
                            .padding(.top, 24)

                        notificationLine
                            .padding(.top, 24)
                            .padding(.bottom, 16)
                    }
                }

                startButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)
            }
        }
        .onAppear {
            configureDatePickerAppearance()
        }
        .fullScreenCover(isPresented: $showClosingTransition) {
            ClosingTransitionView {
                showClosingTransition = false
                onNext()
            }
        }
    }

    // MARK: - Top bar

    private var topBar: some View {
        ZStack {
            OnboardingPhaseIndicator(activePhase: 4)

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
            Text("Almost set.\n")
                .foregroundStyle(Color.white)
            + Text("Last few things.")
                .foregroundStyle(Color(hex: "#8B7DFF"))
        )
        .font(.system(size: 36, weight: .light, design: .serif))
        .multilineTextAlignment(.leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var morningSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Start your day at")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#888888"))

            Text("Your coach sends your morning anchor notification at this time.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#444444"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            schedulePicker(selection: $morningTime)
                .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var eveningSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Daily check-in time")
                .font(.system(size: 13, weight: .light))
                .foregroundStyle(Color(hex: "#888888"))

            Text("Your daily check-in reminder fires at this time.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#444444"))
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 4)

            schedulePicker(selection: $eveningTime)
                .padding(.top, 8)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func schedulePicker(selection: Binding<Date>) -> some View {
        DatePicker(
            "",
            selection: selection,
            displayedComponents: .hourAndMinute,
        )
        .datePickerStyle(.wheel)
        .labelsHidden()
        .frame(height: 110)
        .clipped()
        .padding(.horizontal, 32)
        .background(Color(hex: "#111111"))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color(hex: "#2A2A2A"), lineWidth: 1),
        )
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .colorScheme(.dark)
    }

    private var notificationLine: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: "bell")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))

            Text("Both times require notifications — you'll be asked to allow them now.")
                .font(.system(size: 12, weight: .light))
                .foregroundStyle(Color(hex: "#555555"))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.horizontal, 40)
        .frame(maxWidth: .infinity)
    }

    private var startButton: some View {
        Button(action: handleStartBaseline) {
            HStack(spacing: 6) {
                Text("Start Baseline →")
                    .font(.system(size: 17, weight: .regular))
            }
            .foregroundStyle(Color.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color(hex: "#7C5CBF"))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    // MARK: - Actions

    private func handleStartBaseline() {
        onboarding.setSchedule(morningTime: morningTime, eveningTime: eveningTime)

        let morning = morningTime
        let evening = eveningTime

        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                switch settings.authorizationStatus {
                case .notDetermined:
                    UNUserNotificationCenter.current().requestAuthorization(
                        options: [.alert, .badge, .sound],
                    ) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                NotificationScheduler.shared.scheduleMorningNotification(at: morning)
                                NotificationScheduler.shared.scheduleEveningCheckin(at: evening)
                            }
                            showClosingTransition = true
                        }
                    }
                case .authorized, .provisional, .ephemeral:
                    NotificationScheduler.shared.rescheduleAll(
                        morningTime: morning,
                        eveningTime: evening,
                    )
                    showClosingTransition = true
                default:
                    showClosingTransition = true
                }
            }
        }
    }

    private func configureDatePickerAppearance() {
        #if canImport(UIKit)
        UIDatePicker.appearance().minuteInterval = 1
        UIDatePicker.appearance().tintColor = UIColor(Color(hex: "#8B7DFF"))
        #endif
    }
}

// MARK: - Closing transition

private struct ClosingTransitionView: View {
    let onComplete: () -> Void

    @State private var logoOpacity: Double = 0
    @State private var lineOpacity: Double = 0
    @State private var glowOpacity: Double = 0

    var body: some View {
        ZStack {
            Color(hex: "#0A0A0A")
                .ignoresSafeArea()

            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [
                                    Color(hex: "#3D2070").opacity(0.4),
                                    Color.clear,
                                ],
                                center: .center,
                                startRadius: 0,
                                endRadius: 80,
                            ),
                        )
                        .frame(width: 160, height: 160)
                        .opacity(glowOpacity)

                    CoachPeakIcon(size: 48)
                        .opacity(logoOpacity)
                }

                Text("Your baseline starts now.")
                    .font(.custom("NewYorkSmall-Light", size: 22))
                    .foregroundStyle(Color.white)
                    .multilineTextAlignment(.center)
                    .opacity(lineOpacity)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8)) {
                logoOpacity = 1.0
                glowOpacity = 1.0
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                withAnimation(.easeInOut(duration: 0.8)) {
                    lineOpacity = 1.0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 0.6)) {
                    logoOpacity = 0
                    glowOpacity = 0
                    lineOpacity = 0
                }
            }

            DispatchQueue.main.asyncAfter(deadline: .now() + 3.1) {
                onComplete()
            }
        }
    }
}
