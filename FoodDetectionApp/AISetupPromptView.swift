import SwiftUI

/// Sheet shown when no AI provider is configured, prompting the user to set one up.
struct AISetupPromptView: View {
    @ObservedObject var aiManager = AIProviderManager.shared
    @Environment(\.dismiss) private var dismiss
    @State private var showAPIKeyEntry = false
    @State private var showModelDownload = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer().frame(height: 20)

                Image(systemName: "brain.head.profile")
                    .font(.system(size: 56))
                    .foregroundColor(.green)
                    .accessibilityHidden(true)

                Text("Set Up AI")
                    .font(.title)
                    .fontWeight(.bold)

                Text("FoodSense needs an AI provider to analyze food and generate insights.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                VStack(spacing: 16) {
                    // Card 1: Gemini Cloud
                    Button(action: { showAPIKeyEntry = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "cloud.fill")
                                .font(.title2)
                                .foregroundColor(.blue)
                                .frame(width: 44)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use Gemini Cloud")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Enter your Google AI API key for the best accuracy")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Use Gemini Cloud")
                    .accessibilityHint("Enter your Google AI API key for the best accuracy")

                    // Card 2: On-Device AI
                    Button(action: { showModelDownload = true }) {
                        HStack(spacing: 16) {
                            Image(systemName: "arrow.down.circle.fill")
                                .font(.title2)
                                .foregroundColor(.orange)
                                .frame(width: 44)
                                .accessibilityHidden(true)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Use On-Device AI")
                                    .font(.headline)
                                    .foregroundColor(.primary)
                                Text("Download Gemma 4 (~5.2 GB) for offline use")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                                .accessibilityHidden(true)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(12)
                    }
                    .accessibilityLabel("Use On-Device AI")
                    .accessibilityHint("Download Gemma 4 for offline use, approximately 2.5 gigabytes")
                }
                .padding(.horizontal)

                Spacer()

                Button("Later") {
                    dismiss()
                }
                .foregroundColor(.secondary)
                .padding(.bottom, 32)
                .accessibilityLabel("Set up later")
                .accessibilityHint("Dismiss this screen and configure AI later in Settings")
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showAPIKeyEntry) {
                NavigationView {
                    APIKeyEntryView()
                }
            }
            .sheet(isPresented: $showModelDownload) {
                NavigationView {
                    ModelDownloadView()
                }
            }
            .onChange(of: aiManager.state) { newState in
                if newState == .cloudReady || newState == .localReady {
                    dismiss()
                }
            }
        }
    }
}
