import Foundation
import Security

/// Manages Gemini API key storage in the iOS Keychain.
final class APIKeyManager {

    private let serviceIdentifier = "com.foodsense.gemini-api-key"
    private let accountName = "gemini-api-key"

    // MARK: - Save

    func saveAPIKey(_ key: String) throws {
        deleteAPIKey()

        guard let data = key.data(using: .utf8) else {
            throw NSError(domain: "APIKeyManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to encode API key"])
        }

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountName,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "APIKeyManager", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to save API key to Keychain (status: \(status))"])
        }
    }

    // MARK: - Get

    func getAPIKey() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountName,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let data = result as? Data,
              let key = String(data: data, encoding: .utf8) else {
            return nil
        }
        return key
    }

    // MARK: - Delete

    func deleteAPIKey() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceIdentifier,
            kSecAttrAccount as String: accountName
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Validate

    /// Validate an API key by making a lightweight GET to the Gemini models endpoint.
    func validateAPIKey(_ key: String) async -> Bool {
        // Format check: must start with "AI" and be 30+ characters
        guard key.hasPrefix("AI"), key.count >= 30 else {
            return false
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(key)") else {
            return false
        }

        do {
            let (_, response) = try await URLSession.shared.data(from: url)
            if let http = response as? HTTPURLResponse {
                return http.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
}
