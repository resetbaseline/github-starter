import SwiftUI

struct CheckInFlow: View {
    @StateObject private var viewModel = CheckInViewModel()

    var body: some View {
        NavigationStack {
            GoalReviewView()
                .environmentObject(viewModel)
                .navigationTitle("Check-in")
        }
    }
}
