import SwiftUI

struct VoiceLogView: View {
    @StateObject private var voiceManager = VoiceLoggingManager()
    @ObservedObject var nutritionManager = NutritionManager.shared
    @Environment(\.presentationMode) var presentationMode
    @State private var pulseAnimation = false
    @State private var logged = false

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Spacer()

                // Mic Button with Pulse
                ZStack {
                    if voiceManager.isListening {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 140, height: 140)
                            .scaleEffect(pulseAnimation ? 1.3 : 1.0)
                            .opacity(pulseAnimation ? 0.0 : 0.5)
                            .animation(
                                Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: false),
                                value: pulseAnimation
                            )
                    }

                    Button(action: {
                        if voiceManager.isListening {
                            voiceManager.stopListening()
                            pulseAnimation = false
                            // Auto-search after stopping
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                voiceManager.searchTranscript()
                            }
                        } else {
                            voiceManager.startListening()
                            pulseAnimation = true
                        }
                    }) {
                        Image(systemName: voiceManager.isListening ? "stop.fill" : "mic.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                            .frame(width: 100, height: 100)
                            .background(voiceManager.isListening ? Color.red : Color.blue)
                            .clipShape(Circle())
                            .shadow(color: (voiceManager.isListening ? Color.red : Color.blue).opacity(0.4), radius: 10)
                    }
                    .accessibilityLabel(voiceManager.isListening ? "Stop recording" : "Start voice recording")
                }

                Text(voiceManager.isListening ? "Listening..." : "Tap to speak your meal")
                    .font(.headline)
                    .foregroundColor(.secondary)

                // Transcript Display
                if !voiceManager.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("You said:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text(voiceManager.transcript)
                            .font(.body)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                }

                // Loading
                if voiceManager.isSearching {
                    ProgressView("Searching food...")
                        .padding()
                }

                // Error
                if let error = voiceManager.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Food Result Card
                if let food = voiceManager.detectedFood {
                    VStack(spacing: 12) {
                        Text(food.name)
                            .font(.title2.bold())

                        HStack(spacing: 20) {
                            VStack {
                                Text(food.info.calories)
                                    .font(.headline)
                                Text("kcal")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(food.info.protein)
                                    .font(.headline)
                                Text("Protein")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(food.info.carbs)
                                    .font(.headline)
                                Text("Carbs")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            VStack {
                                Text(food.info.fats)
                                    .font(.headline)
                                Text("Fats")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }

                        Button(action: {
                            nutritionManager.logFood(dish: food.name, info: food.info)
                            logged = true
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                presentationMode.wrappedValue.dismiss()
                            }
                        }) {
                            HStack {
                                Image(systemName: logged ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(logged ? "Logged!" : "Log It")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(logged ? Color.green : Color.blue)
                            .cornerRadius(14)
                        }
                        .disabled(logged)
                        .accessibilityLabel(logged ? "Food logged" : "Log this food")
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(16)
                    .padding(.horizontal)
                }

                Spacer()
            }
            .navigationTitle("Voice Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            }
        }
    }
}
