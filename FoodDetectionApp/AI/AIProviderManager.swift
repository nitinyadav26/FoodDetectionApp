import Foundation
import Combine

class AIProviderManager: ObservableObject {
    static let shared = AIProviderManager()

    enum ProviderState: Equatable {
        case cloudReady
        case localReady
        case downloading(Double)
        case noProvider
    }

    @Published var state: ProviderState = .noProvider
    @Published private(set) var activeProvider: (any AIProvider)?

    private init() {}

    /// Called at app startup. For Phase 1, reads legacy Info.plist keys.
    /// Later phases will check user-provided key and local model.
    func initialize() {
        // Phase 1: legacy behavior -- read from Info.plist
        let legacyKey = Bundle.main.infoDictionary?["GEMINI_API_KEY"] as? String
        let proxyURL = Bundle.main.infoDictionary?["PROXY_BASE_URL"] as? String

        if let key = legacyKey, !key.isEmpty {
            activeProvider = GeminiCloudProvider(apiKey: key, proxyBaseURL: nil)
            state = .cloudReady
        } else if let proxy = proxyURL, !proxy.isEmpty {
            activeProvider = GeminiCloudProvider(apiKey: nil, proxyBaseURL: proxy)
            state = .cloudReady
        } else {
            state = .noProvider
        }
    }
}
