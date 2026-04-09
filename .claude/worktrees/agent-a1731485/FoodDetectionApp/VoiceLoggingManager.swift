import Foundation
import Speech
import AVFoundation

class VoiceLoggingManager: ObservableObject {
    @Published var isListening = false
    @Published var transcript = ""
    @Published var errorMessage: String?
    @Published var detectedFood: (name: String, info: NutritionInfo)?
    @Published var isSearching = false

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()

    init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
    }

    func requestPermission(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { status in
            DispatchQueue.main.async {
                switch status {
                case .authorized:
                    completion(true)
                default:
                    self.errorMessage = "Speech recognition permission denied."
                    completion(false)
                }
            }
        }
    }

    func startListening() {
        guard let speechRecognizer = speechRecognizer, speechRecognizer.isAvailable else {
            errorMessage = "Speech recognizer not available."
            return
        }

        requestPermission { [weak self] granted in
            guard let self = self, granted else { return }

            do {
                try self.startRecognition()
            } catch {
                self.errorMessage = "Failed to start: \(error.localizedDescription)"
            }
        }
    }

    private func startRecognition() throws {
        // Cancel any ongoing task
        recognitionTask?.cancel()
        recognitionTask = nil

        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
        try audioSession.setActive(true, options: .notifyOthersOnDeactivation)

        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw NSError(domain: "VoiceLog", code: -1, userInfo: [NSLocalizedDescriptionKey: "Unable to create recognition request."])
        }
        recognitionRequest.shouldReportPartialResults = true

        let inputNode = audioEngine.inputNode
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { [weak self] result, error in
            guard let self = self else { return }

            if let result = result {
                DispatchQueue.main.async {
                    self.transcript = result.bestTranscription.formattedString
                }
            }

            if error != nil || (result?.isFinal ?? false) {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                self.recognitionRequest = nil
                self.recognitionTask = nil
                DispatchQueue.main.async {
                    self.isListening = false
                }
            }
        }

        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        DispatchQueue.main.async {
            self.isListening = true
            self.transcript = ""
            self.errorMessage = nil
            self.detectedFood = nil
        }
    }

    func stopListening() {
        audioEngine.stop()
        recognitionRequest?.endAudio()
        DispatchQueue.main.async {
            self.isListening = false
        }
    }

    func searchTranscript() {
        let query = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            errorMessage = "No transcript to search."
            return
        }

        isSearching = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.searchFood(query: query)
                DispatchQueue.main.async {
                    self.detectedFood = result
                    self.isSearching = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Search failed: \(error.localizedDescription)"
                    self.isSearching = false
                }
            }
        }
    }
}
