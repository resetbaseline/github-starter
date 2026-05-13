import Combine
import SwiftUI

@MainActor
final class CheckInViewModel: ObservableObject {
    @Published var step = 0
}
