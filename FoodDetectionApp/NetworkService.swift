import Foundation
import FirebaseAuth

/// URLSession-based HTTP client singleton with Firebase Auth bearer token attachment.
final class NetworkService {
    static let shared = NetworkService()

    var baseURL: URL

    private let session: URLSession
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.keyDecodingStrategy = .convertFromSnakeCase
        d.dateDecodingStrategy = .iso8601
        return d
    }()

    private let maxRetries = 3

    /// Whether Firebase is configured in this build (GoogleService-Info.plist present).
    /// Mirrors the guard in `AuthManager` so we don't crash on `Auth.auth()` when Firebase is absent.
    private static let firebaseAvailable: Bool = {
        Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist") != nil
    }()

    private init() {
        // Base URL resolution order:
        // 1. `SOCIAL_API_BASE_URL` from Info.plist (set via Build Settings user-defined key)
        // 2. Production default
        // Override at runtime via `NetworkService.shared.baseURL = ...` if needed.
        let infoPlistURL = (Bundle.main.object(forInfoDictionaryKey: "SOCIAL_API_BASE_URL") as? String)
            .flatMap { URL(string: $0) }
        self.baseURL = infoPlistURL ?? URL(string: "http://129.212.246.162:3000")!

        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
    }

    // MARK: - Public generic methods

    func get<T: Decodable>(_ path: String, queryItems: [URLQueryItem]? = nil) async throws -> T {
        let request = try await buildRequest(path: path, method: "GET", queryItems: queryItems)
        return try await execute(request)
    }

    func post<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        var request = try await buildRequest(path: path, method: "POST")
        if let body = body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return try await execute(request)
    }

    func put<T: Decodable>(_ path: String, body: Encodable? = nil) async throws -> T {
        var request = try await buildRequest(path: path, method: "PUT")
        if let body = body {
            request.httpBody = try JSONEncoder().encode(AnyEncodable(body))
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        }
        return try await execute(request)
    }

    func delete<T: Decodable>(_ path: String) async throws -> T {
        let request = try await buildRequest(path: path, method: "DELETE")
        return try await execute(request)
    }

    // MARK: - Internals

    private func buildRequest(path: String, method: String, queryItems: [URLQueryItem]? = nil) async throws -> URLRequest {
        var components = URLComponents(url: baseURL.appendingPathComponent(path), resolvingAgainstBaseURL: false)!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw NetworkError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        // Attach Firebase Auth bearer token if available.
        // Guarded: touching `Auth.auth()` crashes when FirebaseApp.configure() never ran.
        if Self.firebaseAvailable, let user = Auth.auth().currentUser {
            let token = try await user.getIDToken()
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        return request
    }

    private func execute<T: Decodable>(_ request: URLRequest, attempt: Int = 0) async throws -> T {
        do {
            let (data, response) = try await session.data(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }

            switch httpResponse.statusCode {
            case 200...299:
                return try decoder.decode(T.self, from: data)

            case 401:
                throw NetworkError.unauthorized

            case 429:
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await execute(request, attempt: attempt + 1)
                }
                throw NetworkError.rateLimited

            case 500...599:
                if attempt < maxRetries {
                    let delay = pow(2.0, Double(attempt))
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    return try await execute(request, attempt: attempt + 1)
                }
                throw NetworkError.serverError(httpResponse.statusCode)

            default:
                throw NetworkError.httpError(httpResponse.statusCode, data)
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            if attempt < maxRetries {
                let delay = pow(2.0, Double(attempt))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                return try await execute(request, attempt: attempt + 1)
            }
            throw NetworkError.networkFailure(error)
        }
    }
}

// MARK: - Error types

enum NetworkError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case rateLimited
    case serverError(Int)
    case httpError(Int, Data)
    case networkFailure(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid server response"
        case .unauthorized: return "Authentication required. Please sign in again."
        case .rateLimited: return "Too many requests. Please try again later."
        case .serverError(let code): return "Server error (\(code)). Please try again."
        case .httpError(let code, _): return "Request failed with status \(code)."
        case .networkFailure(let error): return error.localizedDescription
        }
    }
}

// MARK: - Type-erased Encodable wrapper

private struct AnyEncodable: Encodable {
    private let _encode: (Encoder) throws -> Void

    init(_ wrapped: Encodable) {
        _encode = wrapped.encode
    }

    func encode(to encoder: Encoder) throws {
        try _encode(encoder)
    }
}
