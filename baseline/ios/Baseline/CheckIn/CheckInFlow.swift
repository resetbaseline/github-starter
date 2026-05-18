import SwiftUI

/// Three-step check-in: goal review → chip reflection → day result. Owns `CheckInViewModel` and navigation chrome.
struct CheckInFlow: View {
    @StateObject private var viewModel = CheckInViewModel()

    var body: some View {
        NavigationStack {
            Group {
                switch viewModel.step {
                case .goalReview:
                    GoalReviewView()
                case .reflection:
                    ReflectionView()
                case .dayResult:
                    DayResultView()
                }
            }
            .environmentObject(viewModel)
            .animation(Theme.Animation.screenTransition, value: viewModel.step)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Theme.Colors.background)
            .navigationTitle("Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(Theme.Colors.background, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if viewModel.canGoBack {
                        Button("Back") {
                            viewModel.goBack()
                        }
                        .font(Theme.Typography.headline())
                        .foregroundStyle(Theme.Colors.textSecondary)
                    }
                }
            }
        }
    }
}
