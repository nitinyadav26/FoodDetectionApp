import Foundation
import Combine

/// Manages download and lifecycle of the on-device Gemma model + vision projector.
final class ModelDownloadManager: NSObject, ObservableObject {
    static let shared = ModelDownloadManager()

    // MARK: - Published State (Main Model)

    @Published var downloadProgress: Double = 0
    @Published var downloadState: DownloadState = .idle
    @Published var isModelAvailable: Bool = false

    // MARK: - Published State (Vision Projector)

    @Published var mmprojDownloadProgress: Double = 0
    @Published var mmprojDownloadState: DownloadState = .idle
    @Published var isMmprojAvailable: Bool = false

    enum DownloadState: Equatable {
        case idle
        case downloading
        case verifying
        case complete
        case failed(String)
    }

    // MARK: - Model Paths

    private let modelDirectoryName = "GemmaModel"

    private let modelFileName = "google_gemma-4-E2B-it-Q4_K_M.gguf"
    private let modelDownloadURL = "https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/google_gemma-4-E2B-it-Q4_K_M.gguf"

    private let mmprojFileName = "mmproj-google_gemma-4-E2B-it-f16.gguf"
    private let mmprojDownloadURL = "https://huggingface.co/bartowski/google_gemma-4-E2B-it-GGUF/resolve/main/mmproj-google_gemma-4-E2B-it-f16.gguf"

    var modelPath: String {
        modelDirectory.appendingPathComponent(modelFileName).path
    }

    var mmprojPath: String {
        modelDirectory.appendingPathComponent(mmprojFileName).path
    }

    var modelSizeOnDisk: Int64 {
        fileSize(atPath: modelPath)
    }

    var mmprojSizeOnDisk: Int64 {
        fileSize(atPath: mmprojPath)
    }

    private var modelDirectory: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent(modelDirectoryName)
    }

    // MARK: - Private

    private var downloadTask: URLSessionDownloadTask?
    private var mmprojTask: URLSessionDownloadTask?
    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: .main)
    }()

    // MARK: - Init

    override init() {
        super.init()
        cleanupStaleFiles()
        checkModelAvailable()
        checkMmprojAvailable()
    }

    private func cleanupStaleFiles() {
        let staleNames = [
            "gemma-4-e4b.bin",
            "gemma-4-E4B-it.litertlm",
            "gemma-4-E4B-it-Q4_K_S.gguf",
            "google_gemma-4-E4B-it-Q4_K_S.gguf",
            "google_gemma-4-E4B-it-Q2_K.gguf",
            "mmproj-gemma-4-E2B-it-f16.gguf"
        ]
        let dir = modelDirectory
        for name in staleNames {
            let path = dir.appendingPathComponent(name).path
            if FileManager.default.fileExists(atPath: path) {
                try? FileManager.default.removeItem(atPath: path)
            }
        }
    }

    // MARK: - Check Availability

    func checkModelAvailable() {
        isModelAvailable = validateGGUF(atPath: modelPath)
        if isModelAvailable { downloadState = .complete }
    }

    func checkMmprojAvailable() {
        isMmprojAvailable = validateGGUF(atPath: mmprojPath)
        if isMmprojAvailable { mmprojDownloadState = .complete }
    }

    private func validateGGUF(atPath path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path),
              let handle = FileHandle(forReadingAtPath: path) else { return false }
        let magic = handle.readData(ofLength: 4)
        handle.closeFile()
        let valid = magic == Data([0x47, 0x47, 0x55, 0x46]) // "GGUF"
        if !valid {
            try? FileManager.default.removeItem(atPath: path)
        }
        return valid
    }

    // MARK: - Model Download

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

    // MARK: - Vision Projector Download

    func startMmprojDownload() async {
        guard mmprojDownloadState != .downloading else { return }
        guard let url = URL(string: mmprojDownloadURL) else {
            mmprojDownloadState = .failed("Invalid download URL")
            return
        }
        try? FileManager.default.createDirectory(at: modelDirectory, withIntermediateDirectories: true)
        mmprojDownloadProgress = 0
        mmprojDownloadState = .downloading
        let task = urlSession.downloadTask(with: url)
        self.mmprojTask = task
        task.resume()
    }

    func cancelMmprojDownload() {
        mmprojTask?.cancel()
        mmprojTask = nil
        mmprojDownloadState = .idle
        mmprojDownloadProgress = 0
    }

    func deleteMmproj() {
        try? FileManager.default.removeItem(atPath: mmprojPath)
        isMmprojAvailable = false
        mmprojDownloadState = .idle
        mmprojDownloadProgress = 0
    }

    // MARK: - Helpers

    private func fileSize(atPath path: String) -> Int64 {
        guard let attrs = try? FileManager.default.attributesOfItem(atPath: path),
              let size = attrs[.size] as? Int64 else { return 0 }
        return size
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate {
    nonisolated func urlSession(_ session: URLSession, downloadTask task: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        MainActor.assumeIsolated {
            let isModel = (task == self.downloadTask)
            let isMmproj = (task == self.mmprojTask)

            // Determine destination
            let fileName = isModel ? modelFileName : mmprojFileName

            // Check HTTP status
            if let http = task.response as? HTTPURLResponse, http.statusCode != 200 {
                let msg = "Download failed with HTTP \(http.statusCode)"
                if isModel { downloadState = .failed(msg); self.downloadTask = nil }
                if isMmproj { mmprojDownloadState = .failed(msg); self.mmprojTask = nil }
                return
            }

            // Validate GGUF magic
            let ggufMagic = Data([0x47, 0x47, 0x55, 0x46])
            guard let handle = try? FileHandle(forReadingFrom: location),
                  handle.readData(ofLength: 4) == ggufMagic else {
                let msg = "Downloaded file is not a valid GGUF. The server may have returned an error page."
                if isModel { downloadState = .failed(msg); self.downloadTask = nil }
                if isMmproj { mmprojDownloadState = .failed(msg); self.mmprojTask = nil }
                return
            }
            try? handle.close()

            // Move to destination
            let destination = modelDirectory.appendingPathComponent(fileName)
            do {
                if FileManager.default.fileExists(atPath: destination.path) {
                    try FileManager.default.removeItem(at: destination)
                }
                try FileManager.default.moveItem(at: location, to: destination)

                if isModel {
                    isModelAvailable = true
                    downloadState = .complete
                    downloadProgress = 1.0
                    self.downloadTask = nil
                }
                if isMmproj {
                    isMmprojAvailable = true
                    mmprojDownloadState = .complete
                    mmprojDownloadProgress = 1.0
                    self.mmprojTask = nil
                }
            } catch {
                let msg = "Failed to save: \(error.localizedDescription)"
                if isModel { downloadState = .failed(msg); self.downloadTask = nil }
                if isMmproj { mmprojDownloadState = .failed(msg); self.mmprojTask = nil }
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, downloadTask task: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        MainActor.assumeIsolated {
            guard totalBytesExpectedToWrite > 0 else { return }
            let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
            if task == self.downloadTask {
                downloadProgress = progress
            } else if task == self.mmprojTask {
                mmprojDownloadProgress = progress
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        MainActor.assumeIsolated {
            guard let error, (error as NSError).code != NSURLErrorCancelled else { return }
            let msg = error.localizedDescription
            if (task as? URLSessionDownloadTask) == self.downloadTask {
                downloadState = .failed(msg)
                self.downloadTask = nil
            } else if (task as? URLSessionDownloadTask) == self.mmprojTask {
                mmprojDownloadState = .failed(msg)
                self.mmprojTask = nil
            }
        }
    }
}
