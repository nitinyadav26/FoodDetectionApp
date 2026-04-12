import Foundation
import Combine

/// Manages download and lifecycle of the on-device Gemma 4 E4B model.
final class ModelDownloadManager: NSObject, ObservableObject {
    static let shared = ModelDownloadManager()

    // MARK: - Published State

    @Published var downloadProgress: Double = 0
    @Published var downloadState: DownloadState = .idle
    @Published var isModelAvailable: Bool = false

    // MARK: - Download State Enum

    enum DownloadState: Equatable {
        case idle
        case downloading
        case verifying
        case complete
        case failed(String)
    }

    // MARK: - Model Path

    private let modelDirectoryName = "GemmaModel"
    private let modelFileName = "google_gemma-4-E4B-it-Q4_K_S.gguf"
    private let modelDownloadURL = "https://huggingface.co/bartowski/google_gemma-4-E4B-it-GGUF/resolve/main/google_gemma-4-E4B-it-Q4_K_S.gguf"

    var modelPath: String {
        modelDirectory.appendingPathComponent(modelFileName).path
    }

    var modelSizeOnDisk: Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: modelPath),
              let size = attrs[.size] as? Int64 else {
            return 0
        }
        return size
    }

    private var modelDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(modelDirectoryName)
    }

    // MARK: - Private

    private var downloadTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    // MARK: - Init

    override init() {
        super.init()
        cleanupStaleFiles()
        checkModelAvailable()
    }

    /// Remove old model files from prior filename conventions
    private func cleanupStaleFiles() {
        let staleNames = [
            "gemma-4-e4b.bin",
            "gemma-4-E4B-it.litertlm",
            "gemma-4-E4B-it-Q4_K_S.gguf"
        ]
        let dir = modelDirectory
        for name in staleNames {
            let path = dir.appendingPathComponent(name).path
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
    }

    // MARK: - Public Methods

    func checkModelAvailable() {
        let exists = FileManager.default.fileExists(atPath: modelPath)
        // Validate GGUF magic bytes ("GGUF" = 0x47475546) to reject corrupt/HTML downloads
        let valid: Bool
        if exists, let handle = FileHandle(forReadingAtPath: modelPath) {
            let magic = handle.readData(ofLength: 4)
            handle.closeFile()
            valid = magic == Data([0x47, 0x47, 0x55, 0x46]) // "GGUF"
            if !valid {
                // Delete corrupt file (e.g. HTML redirect page)
                try? FileManager.default.removeItem(atPath: modelPath)
            }
        } else {
            valid = false
        }
        isModelAvailable = valid
        if valid {
            downloadState = .complete
        }
    }

    func startDownload() async {
        guard downloadState != .downloading else { return }

        guard let url = URL(string: modelDownloadURL) else {
            downloadState = .failed("Invalid download URL")
            return
        }

        try? FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)

        downloadProgress = 0
        downloadState = .downloading

        let task = urlSession.downloadTask(with: url)
        self.downloadTask = task
        task.resume()
    }

    func cancelDownload() {
        downloadTask?.cancel()
        downloadTask = nil
        downloadState = .idle
        downloadProgress = 0
    }

    func deleteModel() {
        try? FileManager.default.removeItem(atPath: modelPath)
        isModelAvailable = false
        downloadState = .idle
        downloadProgress = 0
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        MainActor.assumeIsolated {
            downloadState = .verifying

            // Check HTTP status — reject non-200 responses
            if let httpResponse = downloadTask.response as? HTTPURLResponse,
               httpResponse.statusCode != 200 {
                downloadState = .failed("Download failed with HTTP \(httpResponse.statusCode)")
                self.downloadTask = nil
                return
            }

            // Validate GGUF magic bytes before moving the file
            let ggufMagic = Data([0x47, 0x47, 0x55, 0x46]) // "GGUF"
            guard let handle = try? FileHandle(forReadingFrom: location),
                  handle.readData(ofLength: 4) == ggufMagic else {
                downloadState = .failed("Downloaded file is not a valid GGUF model. The server may have returned an error page.")
                self.downloadTask = nil
                return
            }
            try? handle.close()

            let destination = modelDirectory.appendingPathComponent(modelFileName)

            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)
                isModelAvailable = true
                downloadState = .complete
                downloadProgress = 1.0
            } catch {
                downloadState = .failed("Failed to save model: \(error.localizedDescription)")
            }

            self.downloadTask = nil
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        MainActor.assumeIsolated {
            if totalBytesExpectedToWrite > 0 {
                downloadProgress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        MainActor.assumeIsolated {
            if let error = error, (error as NSError).code != NSURLErrorCancelled {
                downloadState = .failed(error.localizedDescription)
            }
            self.downloadTask = nil
        }
    }
}
