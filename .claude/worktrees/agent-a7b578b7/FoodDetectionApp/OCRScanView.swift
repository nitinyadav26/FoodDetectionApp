import SwiftUI

struct OCRScanView: View {
    @ObservedObject var nutritionManager = NutritionManager.shared
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var showCamera = false
    @State private var capturedImage: UIImage?
    @State private var parsedNutrition: NutritionInfo?
    @State private var productName: String = "Scanned Product"
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var logged = false
    @State private var servingSize: Double = 100

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Label Scanner")
                            .font(.title2.bold())
                        Text("Scan nutrition labels with AI OCR")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Camera / Image
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
                            Image(systemName: "doc.text.viewfinder")
                                .font(.system(size: 50))
                                .foregroundColor(.blue)
                            Text("Scan Nutrition Label")
                                .font(.headline)
                            Text("Point your camera at a nutrition facts label")
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

                if isProcessing {
                    ProgressView("Reading label...")
                        .padding()
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Parsed Result Card
                if let info = parsedNutrition {
                    VStack(spacing: 16) {
                        // Product name (editable)
                        HStack {
                            Image(systemName: "tag.fill")
                                .foregroundColor(.blue)
                            TextField("Product Name", text: $productName)
                                .font(.title3.bold())
                        }
                        .padding(.horizontal)

                        Divider()

                        // Nutrition Card
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Nutrition Facts (per 100g)")
                                .font(.caption)
                                .foregroundColor(.secondary)

                            NutritionRow(label: "Calories", value: "\(info.calories) kcal", icon: "flame.fill", color: .green)
                            NutritionRow(label: "Protein", value: "\(info.protein)g", icon: "figure.strengthtraining.traditional", color: .blue)
                            NutritionRow(label: "Carbohydrates", value: "\(info.carbs)g", icon: "leaf.fill", color: .orange)
                            NutritionRow(label: "Fats", value: "\(info.fats)g", icon: "drop.fill", color: .red)

                            if let micros = info.micros, !micros.isEmpty {
                                Divider()
                                Text("Micronutrients")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 6) {
                                    ForEach(micros.sorted(by: >), id: \.key) { key, value in
                                        HStack {
                                            Text(key)
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            Spacer()
                                            Text(value)
                                                .font(.caption.bold())
                                        }
                                    }
                                }
                            }
                        }

                        Divider()

                        // Serving Size
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Serving Size")
                                    .font(.subheadline)
                                Spacer()
                                Text("\(Int(servingSize))g")
                                    .font(.headline.bold())
                                    .foregroundColor(.blue)
                            }
                            Slider(value: $servingSize, in: 10...500, step: 5)
                                .tint(.blue)
                        }

                        // Log Button
                        Button(action: logScannedFood) {
                            HStack {
                                Image(systemName: logged ? "checkmark.circle.fill" : "plus.circle.fill")
                                Text(logged ? "Logged!" : "Log This Food")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(logged ? Color.green : Color.blue)
                            .cornerRadius(14)
                        }
                        .disabled(logged)
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
            OCRImagePicker(image: $capturedImage)
                .onDisappear {
                    if capturedImage != nil {
                        processImage()
                    }
                }
        }
    }

    func processImage() {
        guard let image = capturedImage else { return }
        guard networkMonitor.isConnected else {
            errorMessage = "No internet connection."
            return
        }

        isProcessing = true
        errorMessage = nil
        parsedNutrition = nil
        logged = false

        Task {
            do {
                let result = try await APIService.shared.ocrNutritionLabel(image: image)
                DispatchQueue.main.async {
                    self.productName = result.name
                    self.parsedNutrition = result.info
                    self.isProcessing = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "OCR failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }

    func logScannedFood() {
        guard let info = parsedNutrition else { return }
        nutritionManager.logFood(dish: productName, info: info, weight: servingSize)
        logged = true
    }
}

struct NutritionRow: View {
    let label: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 24)
            Text(label)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline.bold())
        }
        .padding(.vertical, 2)
    }
}

struct OCRImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: OCRImagePicker
        init(_ parent: OCRImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage { parent.image = img }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
