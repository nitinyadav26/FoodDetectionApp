import SwiftUI

struct ChatMessage: Identifiable, Codable {
    var id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date
}

struct NutritionistChatView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var healthManager = HealthKitManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var messages: [ChatMessage] = []
    @State private var inputText = ""
    @State private var isLoading = false

    private let quickChips = [
        "What should I eat now?",
        "Am I eating enough protein?",
        "How are my macros today?",
        "Give me a snack idea",
        "Rate my diet today"
    ]

    private let storageKey = "nutritionist_chat_history"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                VStack(alignment: .leading) {
                    Text("AI Nutritionist")
                        .font(.title2.bold())
                    Text("Chat with your personal nutrition expert")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: startNewChat) {
                    Image(systemName: "plus.message.fill")
                        .font(.title2)
                        .foregroundColor(.blue)
                }
                .accessibilityLabel("New Chat")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))

            // Chat Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(messages) { msg in
                            ChatBubble(message: msg)
                                .id(msg.id)
                        }

                        if isLoading {
                            HStack {
                                ProgressView()
                                    .padding(.trailing, 4)
                                Text("Thinking...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                Spacer()
                            }
                            .padding(.horizontal)
                            .id("loading")
                        }
                    }
                    .padding(.vertical)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            // Quick Chips
            if messages.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(quickChips, id: \.self) { chip in
                            Button(action: { sendMessage(chip) }) {
                                Text(chip)
                                    .font(.caption)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(Color.blue.opacity(0.1))
                                    .foregroundColor(.blue)
                                    .cornerRadius(16)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                }
            }

            // Input Bar
            HStack(spacing: 10) {
                TextField("Ask about nutrition...", text: $inputText)
                    .textFieldStyle(.roundedBorder)
                    .submitLabel(.send)
                    .onSubmit {
                        sendMessage(inputText)
                    }

                Button(action: { sendMessage(inputText) }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundColor(inputText.trimmingCharacters(in: .whitespaces).isEmpty ? .gray : .blue)
                }
                .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                .accessibilityLabel("Send message")
            }
            .padding()
            .background(Color(UIColor.secondarySystemBackground))
        }
        .onAppear(perform: loadHistory)
    }

    // MARK: - Actions

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        inputText = ""

        let userMsg = ChatMessage(role: "user", content: trimmed, timestamp: Date())
        messages.append(userMsg)
        saveHistory()

        guard networkMonitor.isConnected else {
            let offline = ChatMessage(role: "assistant", content: "You're offline. Please connect to the internet to chat.", timestamp: Date())
            messages.append(offline)
            saveHistory()
            return
        }

        isLoading = true

        // Build context from recent messages
        let recentContext = messages.suffix(10).map { "\($0.role): \($0.content)" }.joined(separator: "\n")
        let healthData = "Steps: \(healthManager.stepCount), Sleep: \(healthManager.sleepHours), Water: \(healthManager.waterIntake)L, Burn: \(healthManager.activeCalories)"
        let foodHistory = nutritionManager.getHistory(days: 7)

        Task {
            do {
                let response = try await APIService.shared.getCoachAdvice(
                    userStats: nutritionManager.userStats,
                    logs: nutritionManager.todayLogs,
                    healthData: healthData,
                    historyTOON: "Recent chat:\n\(recentContext)\n\nFood History:\n\(foodHistory)",
                    userQuery: trimmed
                )
                DispatchQueue.main.async {
                    let assistantMsg = ChatMessage(role: "assistant", content: response, timestamp: Date())
                    self.messages.append(assistantMsg)
                    self.isLoading = false
                    self.saveHistory()
                }
            } catch {
                DispatchQueue.main.async {
                    let errMsg = ChatMessage(role: "assistant", content: "Sorry, I encountered an error. Please try again.", timestamp: Date())
                    self.messages.append(errMsg)
                    self.isLoading = false
                    self.saveHistory()
                }
            }
        }
    }

    func startNewChat() {
        messages.removeAll()
        saveHistory()
    }

    func saveHistory() {
        if let data = try? JSONEncoder().encode(messages) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    func loadHistory() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
           let saved = try? JSONDecoder().decode([ChatMessage].self, from: data) {
            messages = saved
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var isUser: Bool { message.role == "user" }

    var body: some View {
        HStack {
            if isUser { Spacer(minLength: 50) }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? Color.blue : Color(UIColor.secondarySystemBackground))
                    .foregroundColor(isUser ? .white : .primary)
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            if !isUser { Spacer(minLength: 50) }
        }
        .padding(.horizontal)
    }
}
