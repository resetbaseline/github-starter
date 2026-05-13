import Combine
import SwiftUI

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var isLoading = false
}
