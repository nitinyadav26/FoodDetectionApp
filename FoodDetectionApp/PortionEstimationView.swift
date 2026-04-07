import SwiftUI

struct PortionEstimationView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var estimatedGrams: Double = 100
    @State private var foodName: String = ""
    @State private var nutritionInfo: NutritionInfo?
    @State private var isAnalyzing = false
    @State private var errorMessage: String?
    @State private var logged = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Portion Estimation")
                            .font(.title2.bold())
                        Text("AI estimates your serving size")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Camera/Image
                if let image = capturedImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 250)
                        .cornerRadius(14)
                        .padding(.horizontal)

                    Button(action: { showCamera = true }) {
                        Label("Retake Photo", systemImage: "camera.fill")
                            .font(.subheadline)
                    }
                } else {
                    Button(action: { showCamera = true }) {
                        VStack(spacing: 12) {
                            Image(systemName: "camera.viewfinder")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            Text("Take a Photo of Your Food")
                                .font(.headline)
                            Text("AI will estimate the portion size")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(14)
                    }
                    .padding(.horizontal)
                }

                if isAnalyzing {
                    ProgressView("Analyzing portion...")
                        .padding()
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Results
                if nutritionInfo != nil {
                    VStack(spacing: 16) {
                        Text(foodName)
                            .font(.title3.bold())

                        // Slider
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Portion Size")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(estimatedGrams))g")
                                    .font(.headline.bold())
                                    .foregroundColor(.blue)
                            }
                            Slider(value: $estimatedGrams, in: 10...1000, step: 10)
                                .tint(.blue)
                                .accessibilityLabel("Portion size slider")
                                .accessibilityValue("\(Int(estimatedGrams)) grams")
                        }
                        .padding(.horizontal)

                        // Nutrition recalc
                        let scaled = scaledNutrition
                        HStack(spacing: 16) {
                            NutritionPill(label: "Cals", value: scaled.calories, color: .green)
                            NutritionPill(label: "Prot", value: scaled.protein, color: .blue)
                            NutritionPill(label: "Carb", value: scaled.carbs, color: .orange)
                            NutritionPill(label: "Fat", value: scaled.fats, color: .red)
                        }
                        .padding(.horizontal)

                        // Log Button
                        Button(action: logFood) {
                            HStack {
                                Image(systemName: logged ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(logged ? "Logged!" : "Log This Meal")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(logged ? Color.green : Color.blue)
                            .cornerRadius(14)
                        }
                        .disabled(logged)
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .sheet(isPresented: $showCamera) {
            ImagePicker(image: $capturedImage)
                .onDisappear {
                    if capturedImage != nil {
                        analyzeImage()
                    }
                }
        }
    }

    var scaledNutrition: (calories: String, protein: String, carbs: String, fats: String) {
        guard let info = nutritionInfo else {
            return ("0", "0", "0", "0")
        }
        let ratio = estimatedGrams / 100.0

        func scale(_ val: String) -> String {
            let filtered = val.components(separatedBy: CharacterSet(charactersIn: "0123456789.").inverted).joined()
            let num = Double(filtered) ?? 0
            return String(Int(num * ratio))
        }

        return (scale(info.calories), scale(info.protein), scale(info.carbs), scale(info.fats))
    }

    func analyzeImage() {
        guard let image = capturedImage else { return }
        guard networkMonitor.isConnected else {
            errorMessage = "No internet connection."
            return
        }

        isAnalyzing = true
        errorMessage = nil
        logged = false

        Task {
            do {
                let result = try await APIService.shared.estimatePortion(image: image)
                DispatchQueue.main.async {
                    self.foodName = result.name
                    self.nutritionInfo = result.info
                    self.estimatedGrams = result.estimatedGrams
                    self.isAnalyzing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Analysis failed: \(error.localizedDescription)"
                    self.isAnalyzing = false
                }
            }
        }
    }

    func logFood() {
        guard let info = nutritionInfo else { return }
        let scaled = nutritionManager.calculateNutrition(for: info, weight: estimatedGrams)
        nutritionManager.logFood(dish: foodName, info: scaled)
        logged = true
    }
}

struct NutritionPill: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .foregroundColor(color)
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(color.opacity(0.1))
        .cornerRadius(10)
    }
}

// MARK: - Image Picker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .camera
        picker.allowsEditing = false
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker

        init(_ parent: ImagePicker) {
            self.parent = parent
        }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
