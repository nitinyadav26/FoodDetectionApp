import SwiftUI

struct BeforeAfterView: View {
    @ObservedObject var networkMonitor = NetworkMonitor.shared

    @State private var beforeImage: UIImage?
    @State private var afterImage: UIImage?
    @State private var showPickerFor: ImageSlot?
    @State private var analysisResult: String = ""
    @State private var isAnalyzing = false
    @State private var errorMessage: String?

    enum ImageSlot: Identifiable {
        case before, after
        var id: String { self == .before ? "before" : "after" }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text("Before & After")
                            .font(.title2.bold())
                        Text("Compare meals and consumption")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)

                // Image Slots
                HStack(spacing: 12) {
                    ImageSlotView(
                        title: "Before",
                        image: beforeImage,
                        color: .blue
                    ) {
                        showPickerFor = .before
                    }

                    ImageSlotView(
                        title: "After",
                        image: afterImage,
                        color: .orange
                    ) {
                        showPickerFor = .after
                    }
                }
                .padding(.horizontal)

                // Analyze Button
                if beforeImage != nil && afterImage != nil {
                    Button(action: analyzeImages) {
                        HStack {
                            if isAnalyzing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            } else {
                                Image(systemName: "sparkles")
                            }
                            Text(isAnalyzing ? "Analyzing..." : "Compare & Analyze")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(isAnalyzing ? Color.gray : Color.purple)
                        .cornerRadius(14)
                    }
                    .disabled(isAnalyzing)
                    .padding(.horizontal)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                }

                // Analysis Result
                if !analysisResult.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Image(systemName: "chart.bar.doc.horizontal.fill")
                                .foregroundColor(.purple)
                            Text("Consumption Analysis")
                                .font(.headline)
                        }

                        Text(analysisResult)
                            .font(.body)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .background(Color(UIColor.secondarySystemBackground))
                    .cornerRadius(14)
                    .padding(.horizontal)
                }

                // Reset
                if beforeImage != nil || afterImage != nil {
                    Button(action: reset) {
                        Label("Reset", systemImage: "arrow.counterclockwise")
                            .font(.subheadline)
                            .foregroundColor(.red)
                    }
                    .padding(.top, 8)
                }

                Spacer(minLength: 20)
            }
            .padding(.vertical)
        }
        .sheet(item: $showPickerFor) { slot in
            BeforeAfterImagePicker(image: slot == .before ? $beforeImage : $afterImage)
        }
    }

    func analyzeImages() {
        guard let before = beforeImage, let after = afterImage else { return }
        guard networkMonitor.isConnected else {
            errorMessage = "No internet connection."
            return
        }

        isAnalyzing = true
        errorMessage = nil

        Task {
            do {
                let result = try await APIService.shared.compareBeforeAfter(before: before, after: after)
                DispatchQueue.main.async {
                    self.analysisResult = result
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

    func reset() {
        beforeImage = nil
        afterImage = nil
        analysisResult = ""
        errorMessage = nil
    }
}

struct ImageSlotView: View {
    let title: String
    let image: UIImage?
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                if let img = image {
                    Image(uiImage: img)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 150)
                        .clipped()
                        .cornerRadius(10)
                } else {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 30))
                        .foregroundColor(color)
                        .frame(height: 150)
                        .frame(maxWidth: .infinity)
                        .background(color.opacity(0.1))
                        .cornerRadius(10)
                }
                Text(title)
                    .font(.caption.bold())
                    .foregroundColor(color)
            }
        }
        .frame(maxWidth: .infinity)
        .accessibilityLabel("Select \(title.lowercased()) image")
    }
}

struct BeforeAfterImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        // Allow both camera and library
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: BeforeAfterImagePicker
        init(_ parent: BeforeAfterImagePicker) { self.parent = parent }

        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            if let img = info[.originalImage] as? UIImage {
                parent.image = img
            }
            parent.presentationMode.wrappedValue.dismiss()
        }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.presentationMode.wrappedValue.dismiss()
        }
    }
}
