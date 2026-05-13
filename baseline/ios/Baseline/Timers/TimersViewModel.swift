import Combine
import SwiftUI

@MainActor
final class TimersViewModel: ObservableObject {
    @Published var remainingSeconds: Int = 0
}
