import Combine
import SwiftUI

@MainActor
final class ProfileViewModel: ObservableObject {
    @Published var displayName = ""
}
