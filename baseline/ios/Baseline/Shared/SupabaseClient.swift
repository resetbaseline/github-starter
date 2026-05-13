import Foundation
import Supabase

/// Reads `SUPABASE_URL` and `SUPABASE_ANON_KEY` from Info.plist (populated via xcconfig at build time).
enum SupabaseBootstrap {
    static var supabaseURL: URL {
        guard let raw = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_URL") as? String,
              let url = URL(string: raw.trimmingCharacters(in: .whitespacesAndNewlines)),
              !raw.isEmpty
        else {
            fatalError("Missing or invalid SUPABASE_URL in Info.plist / xcconfig.")
        }
        return url
    }

    static var supabaseAnonKey: String {
        guard let key = Bundle.main.object(forInfoDictionaryKey: "SUPABASE_ANON_KEY") as? String,
              !key.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else {
            fatalError("Missing SUPABASE_ANON_KEY in Info.plist / xcconfig.")
        }
        return key.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func makeClient() -> SupabaseClient {
        SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseAnonKey)
    }
}

/// Shared Supabase client for the app process (inject from `BaselineApp` when wiring auth).
final class SupabaseController: ObservableObject {
    let client: SupabaseClient

    init(client: SupabaseClient? = nil) {
        self.client = client ?? SupabaseBootstrap.makeClient()
    }
}
