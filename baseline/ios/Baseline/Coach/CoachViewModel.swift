import Combine
import SwiftUI

@MainActor
final class CoachViewModel: ObservableObject {
    @Published var draftMessage = ""
}
