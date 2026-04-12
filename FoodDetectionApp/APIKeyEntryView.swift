import SwiftUI

/// View for entering, validating, and managing a user-provided Gemini API key.
struct APIKeyEntryView: View {
    @State private var apiKey = ""
    @State private var isValidating = false
    @State private var validationResult: Bool?
    @State private var existingKeyMasked: String?
    @Environment(\.dismiss) private var dismiss

    private let apiKeyManager = APIKeyManager()

    var body: some View {
        Form {
            Section(header: Text("Gemini API Key")) {
                if let masked = existingKeyMasked {
                    HStack {
                        Text("Current key")
                        Spacer()
                        Text("****\(masked)")
                            .foregroundColor(.secondary)
                            .font(.system(.body, design: .monospaced))
                    }
                    .accessibilityLabel("Current API key ending in \(masked)")

                    Button("Clear Key", role: .destructive) {
                        apiKeyManager.deleteAPIKey()
                        AIProviderManager.shared.clearAPIKey()
                        existingKeyMasked = nil
                        validationResult = nil
                        apiKey = ""
                    }
                    .accessibilityLabel("Clear saved API key")
                } else {
                    SecureField("Enter Gemini API Key", text: $apiKey)
                        .textContentType(.password)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .accessibilityLabel("Gemini API Key input")

                    Button(action: validateAndSave) {
                        HStack {
                            if isValidating {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                                    .accessibilityLabel("Validating key")
                            }
                            Text(isValidating ? "Validating..." : "Validate & Save")
                        }
                    }
                    .disabled(apiKey.isEmpty || isValidating)
                    .accessibilityLabel(isValidating ? "Validating API key" : "Validate and save API key")
                }
            }

            // Validation Result
            if let result = validationResult {
                Section {
                    HStack {
                        Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundColor(result ? .green : .red)
                            .accessibilityHidden(true)
                        Text(result ? "Key saved successfully" : "Invalid API key. Check the key and try again.")
                            .foregroundColor(result ? .green : .red)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel(result ? "Key saved successfully" : "Invalid API key")
                }
            }

            Section(header: Text("Get an API Key")) {
                Link(destination: URL(string: "https://aistudio.google.com/app/apikey")!) {
                    HStack {
                        Image(systemName: "link")
                            .accessibilityHidden(true)
                        Text("Google AI Studio")
                        Spacer()
                        Image(systemName: "arrow.up.right.square")
                            .foregroundColor(.secondary)
                            .accessibilityHidden(true)
                    }
                }
                .accessibilityLabel("Get API key from Google AI Studio")
                .accessibilityHint("Opens Google AI Studio in your browser")

                Text("Create a free API key at Google AI Studio. The key is stored securely in your device's Keychain.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Gemini API Key")
        .onAppear {
            loadExistingKey()
        }
    }

    // MARK: - Private

    private func loadExistingKey() {
        if let key = apiKeyManager.getAPIKey(), !key.isEmpty {
            existingKeyMasked = String(key.suffix(4))
        }
    }

    private func validateAndSave() {
        isValidating = true
        validationResult = nil

        Task {
            let isValid = await apiKeyManager.validateAPIKey(apiKey)
            isValidating = false

            if isValid {
                try? apiKeyManager.saveAPIKey(apiKey)
                AIProviderManager.shared.setAPIKey(apiKey)
                validationResult = true
                existingKeyMasked = String(apiKey.suffix(4))
                apiKey = ""
            } else {
                validationResult = false
            }
        }
    }
}
