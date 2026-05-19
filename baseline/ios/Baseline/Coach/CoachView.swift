import SwiftUI

struct CoachView: View {
    @StateObject private var viewModel = CoachViewModel()

    var body: some View {
        ZStack {
            Theme.Colors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                header
                CoachMessageView()
                    .environmentObject(viewModel)
            }
        }
        .background(Theme.Colors.background)
    }

    private var header: some View {
        HStack {
            Text("Coach")
                .font(.system(size: 17, weight: .light))
                .foregroundStyle(Theme.Colors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .background(Theme.Colors.background)
    }
}
