import Foundation

/// URLSession + Supabase Edge helpers (implemented when networking tasks are built).
enum APIClient {
    static let jsonDecoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        return d
    }()
}
