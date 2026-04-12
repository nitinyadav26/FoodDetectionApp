import Foundation
import Combine

/// Manages the active AI provider with 3-tier fallback:
/// 1. User-provided Gemini API key (Keychain)
/// 2. On-device Gemma 4 E4B model
/// 3. Legacy Info.plist API key
final class AIProviderManager: ObservableObject {
    static let shared = AIProviderManager()

    // MARK: - State

    enum ProviderState: Equatable {
        case initializing
        case cloudReady
        case localReady
        case noProvider
    }

    @Published var state: ProviderState = .initializing
    @Published private(set) var activeProvider: (any AIProvider)?

    // MARK: - Dependencies

    private let apiKeyManager = APIKeyManager()
    let modelDownloadManager = ModelDownloadManager.shared

    // MARK: - Legacy Keys

    private let legacyProxyBaseURL: String? = {
        Bundle.main.infoDictionary?["PROXY_BASE_URL"] as? String
    }()

    private let legacyDirectApiKey: String? = {
        Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
    }()

    // MARK: - Init

    init() {
        initialize()
    }

    // MARK: - Initialize / Re-initialize

    func initialize() {
        // Tier 1: User-provided Gemini API key from Keychain
        if let userKey = apiKeyManager.getAPIKey(), !userKey.isEmpty {
            activeProvider = GeminiCloudProvider(apiKey: userKey, proxyBaseURL: nil)
            state = .cloudReady
            return
        }

        // Tier 2: On-device Gemma model
        if modelDownloadManager.isModelAvailable {
            activeProvider = GemmaLocalProvider(modelPath: modelDownloadManager.modelPath)
            state = .localReady
            return
        }

        // Tier 3: Legacy Info.plist key or proxy
        if let proxy = legacyProxyBaseURL, !proxy.isEmpty {
            activeProvider = GeminiCloudProvider(apiKey: nil, proxyBaseURL: proxy)
            state = .cloudReady
            return
        }
        if let key = legacyDirectApiKey, !key.isEmpty {
            activeProvider = GeminiCloudProvider(apiKey: key, proxyBaseURL: nil)
            state = .cloudReady
            return
        }

        // No provider available
        activeProvider = nil
        state = .noProvider
    }

    // MARK: - API Key Management

    func setAPIKey(_ key: String) {
        try? apiKeyManager.saveAPIKey(key)
        initialize()
    }

    func clearAPIKey() {
        apiKeyManager.deleteAPIKey()
        initialize()
    }

    // MARK: - Model Download

    func startModelDownload() async {
        await modelDownloadManager.startDownload()
    }

    func deleteLocalModel() {
        modelDownloadManager.deleteModel()
        initialize()
    }
}
