import SwiftUI

/// View for downloading and managing the on-device Gemma 4 E4B model.
struct ModelDownloadView: View {
    @ObservedObject private var downloadManager = ModelDownloadManager.shared
    @Environment(\.dismiss) private var dismiss

    private var isOSSupported: Bool {
        ProcessInfo.processInfo.operatingSystemVersion.majorVersion >= 17
    }

    private var availableDiskSpace: String {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
              let freeSpace = attrs[.systemFreeSize] as? Int64 else {
            return "Unknown"
        }
        return ByteCountFormatter.string(fromByteCount: freeSpace, countStyle: .file)
    }

    var body: some View {
        Form {
            Section(header: Text("Model Info")) {
                HStack {
                    Text("Model")
                    Spacer()
                    Text("Gemma 4 E4B")
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Model: Gemma 4 E4B")

                HStack {
                    Text("Size")
                    Spacer()
                    Text("~5.2 GB")
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Size: approximately 2.5 gigabytes")

                HStack {
                    Text("Available Space")
                    Spacer()
                    Text(availableDiskSpace)
                        .foregroundColor(.secondary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Available disk space: \(availableDiskSpace)")

                if downloadManager.isModelAvailable {
                    HStack {
                        Text("On Disk")
                        Spacer()
                        Text(ByteCountFormatter.string(fromByteCount: downloadManager.modelSizeOnDisk, countStyle: .file))
                            .foregroundColor(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                }
            }

            if !isOSSupported {
                Section {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                            .accessibilityHidden(true)
                        Text("On-device AI requires iOS 17+")
                            .foregroundColor(.orange)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("On-device AI requires iOS 17 or later")
                }
            }

            Section {
                switch downloadManager.downloadState {
                case .idle:
                    Button(action: startDownload) {
                        HStack {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.blue)
                                .accessibilityHidden(true)
                            Text("Download Model")
                        }
                    }
                    .disabled(!isOSSupported)
                    .accessibilityLabel("Download model")
                    .accessibilityHint(isOSSupported ? "Downloads the Gemma 4 model for on-device AI" : "Requires iOS 17 or later")

                case .downloading:
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Downloading...")
                            Spacer()
                            Text("\(Int(downloadManager.downloadProgress * 100))%")
                                .foregroundColor(.secondary)
                        }
                        ProgressView(value: downloadManager.downloadProgress)
                            .progressViewStyle(LinearProgressViewStyle())
                            .accessibilityLabel("Download progress: \(Int(downloadManager.downloadProgress * 100)) percent")
                    }

                    Button("Cancel Download", role: .destructive) {
                        downloadManager.cancelDownload()
                    }
                    .accessibilityLabel("Cancel download")

                case .verifying:
                    HStack {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle())
                            .accessibilityHidden(true)
                        Text("Verifying model...")
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Verifying downloaded model")

                case .complete:
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .accessibilityHidden(true)
                        Text("Model Ready")
                            .foregroundColor(.green)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Model is ready for use")

                    Button("Delete Model", role: .destructive) {
                        AIProviderManager.shared.deleteLocalModel()
                    }
                    .accessibilityLabel("Delete downloaded model")

                case .failed(let message):
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.red)
                            .accessibilityHidden(true)
                        Text(message)
                            .foregroundColor(.red)
                            .font(.caption)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("Download failed: \(message)")

                    Button(action: startDownload) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                                .accessibilityHidden(true)
                            Text("Retry Download")
                        }
                    }
                    .disabled(!isOSSupported)
                    .accessibilityLabel("Retry download")
                }
            }
        }
        .navigationTitle("On-Device AI")
    }

    private func startDownload() {
        Task {
            await AIProviderManager.shared.startModelDownload()
        }
    }
}
