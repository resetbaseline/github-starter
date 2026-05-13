import SwiftUI

struct TimersView: View {
    @StateObject private var viewModel = TimersViewModel()

    var body: some View {
        NavigationStack {
            TimerRunningView()
                .environmentObject(viewModel)
                .navigationTitle("Timers")
        }
    }
}
