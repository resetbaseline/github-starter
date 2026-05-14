import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var auth: AuthManager
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.md) {
                    homeHeader

                    HomeDayProgressCard()

                    StreakCardView()

                    GoalsListView()

                    if let intention = viewModel.tomorrowIntention, !intention.isEmpty {
                        HomeTomorrowCard(text: intention)
                    }
                }
                .padding(Theme.Spacing.sm)
            }
            .background(Theme.Colors.background)
            .navigationTitle("Today")
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .refreshable {
                await viewModel.refresh()
            }
            .overlay(alignment: .top) {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(Theme.Colors.accent)
                        .padding(.top, Theme.Spacing.xs)
                }
            }
        }
        .environmentObject(viewModel)
    }

    private var homeHeader: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text(greetingLine)
                .font(Theme.Typography.title2())
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)

            Text(viewModel.formattedToday)
                .font(Theme.Typography.subheadline())
                .foregroundStyle(Theme.Colors.textMuted)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var greetingLine: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let prefix: String
        switch hour {
        case 0 ..< 12: prefix = "Good morning"
        case 12 ..< 17: prefix = "Good afternoon"
        default: prefix = "Good evening"
        }
        if let name = auth.onboardingPreferredName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return "\(prefix), \(name)"
        }
        return prefix
    }
}

// MARK: - Day progress + tomorrow (home-only)

private struct HomeDayProgressCard: View {
    @EnvironmentObject private var viewModel: HomeViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.sm) {
            Text("This day")
                .font(Theme.Typography.caption1())
                .foregroundStyle(Theme.Colors.textSecondary)

            HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xs) {
                Text("\(viewModel.goalsCompleted)")
                    .font(Theme.Typography.title1())
                    .foregroundStyle(Theme.Colors.textPrimary)
                Text("of \(viewModel.goalsTotal) goals marked done")
                    .font(Theme.Typography.callout())
                    .foregroundStyle(Theme.Colors.textSecondary)
            }

            HStack(spacing: Theme.Spacing.xs) {
                Text("Status")
                    .font(Theme.Typography.caption1())
                    .foregroundStyle(Theme.Colors.textMuted)
                Text(viewModel.dayStatusLabel)
                    .font(Theme.Typography.caption1())
                    .foregroundStyle(Theme.Colors.textPrimary)
            }

            ProgressView(value: progressValue, total: 1)
                .tint(Theme.Colors.accent)
                .scaleEffect(x: 1, y: 1.25, anchor: .center)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Goals \(viewModel.goalsCompleted) of \(viewModel.goalsTotal) done, status \(viewModel.dayStatusLabel)")
    }

    private var progressValue: Double {
        guard viewModel.goalsTotal > 0 else { return 0 }
        return Double(viewModel.goalsCompleted) / Double(viewModel.goalsTotal)
    }
}

private struct HomeTomorrowCard: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xs) {
            Text("Tomorrow")
                .font(Theme.Typography.caption1())
                .foregroundStyle(Theme.Colors.textSecondary)
            Text(text)
                .font(Theme.Typography.callout())
                .foregroundStyle(Theme.Colors.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(Theme.Spacing.sm)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Theme.Colors.surface)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.Radius.card, style: .continuous)
                .stroke(Theme.Colors.border, lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tomorrow intention: \(text)")
    }
}
