import SwiftUI

struct CoachView: View {
    @StateObject private var viewModel = CoachViewModel()

    var body: some View {
        NavigationStack {
            CoachMessageView()
                .environmentObject(viewModel)
                .navigationTitle("Coach")
        }
    }
}
