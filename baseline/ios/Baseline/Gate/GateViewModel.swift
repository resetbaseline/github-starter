import Combine
import SwiftUI

@MainActor
final class GateViewModel: ObservableObject {
    @Published var reason = ""
}
