import Foundation
import Supabase

/// Invokes Supabase Edge Functions when an authenticated session is present.
enum EdgeFunctionsService {
    private static let client = SupabaseBootstrap.makeClient()

    static func processFocusComplete(durationMinutes: Int) async {
        guard durationMinutes >= 10 else { return }
        struct Body: Encodable {
            let durationMinutes: Int
        }
        do {
            _ = try await client.functions.invoke(
                "process-focus-complete",
                options: FunctionInvokeOptions(body: Body(durationMinutes: durationMinutes)),
            )
        } catch {
            // Expected until Supabase auth session is wired.
        }
    }

    static func processAnchorComplete(anchorId: UUID, anchorText: String) async {
        struct Body: Encodable {
            let anchorId: String
            let anchorText: String
        }
        do {
            _ = try await client.functions.invoke(
                "process-anchor-complete",
                options: FunctionInvokeOptions(
                    body: Body(anchorId: anchorId.uuidString, anchorText: anchorText),
                ),
            )
        } catch {
            // Expected until Supabase auth session is wired.
        }
    }
}
