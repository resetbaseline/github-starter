import Combine
import SwiftUI

@MainActor
final class MessageToSelfViewModel: ObservableObject {
    @Published var bodyText = ""
}
