import SwiftUI
import Combine

struct ContentView: View {
    @AppStorage("hasOnboarded") var hasOnboarded: Bool = false
    @StateObject private var networkMonitor = NetworkMonitor.shared
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var socialManager = SocialManager.shared
    @StateObject private var aiManager = AIProviderManager.shared
    @State private var showAISetup = false

    var body: some View {
        if !hasOnboarded {
            OnboardingView()
                .onDisappear {
                    hasOnboarded = true
                }
        } else if authManager.isLoading {
            VStack {
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Text("Loading...")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.top, 8)
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("Loading, please wait")
        } else if !authManager.isSignedIn {
            LoginView()
        } else {
            VStack(spacing: 0) {
                if !networkMonitor.isConnected {
                    HStack {
                        Image(systemName: "wifi.slash")
                            .accessibilityHidden(true)
                        Text("No Internet Connection")
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 6)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("No internet connection")
                }
                TabView {
                    DashboardView()
                        .tabItem {
                            Image(systemName: "chart.bar.fill")
                            Text("Dashboard")
                        }

                    ScanView()
                        .tabItem {
                            Image(systemName: "camera.viewfinder")
                            Text("Scan")
                        }

                    CoachView()
                        .tabItem {
                            Image(systemName: "brain.head.profile")
                            Text("AI Coach")
                        }

                    BluetoothPairingView()
                        .tabItem {
                            Image(systemName: "wave.3.right.circle")
                            Text("Pair Scale")
                        }

                    SocialTabView()
                        .tabItem {
                            Image(systemName: "person.2.fill")
                            Text("Social")
                        }
                        .badge(socialManager.pendingRequestCount)

                    ProfileView()
                        .tabItem {
                            Image(systemName: "person.crop.circle")
                            Text("Profile")
                        }
                }
                .accentColor(.green)
            }
            .sheet(isPresented: $showAISetup) {
                AISetupPromptView()
            }
            .onAppear {
                if aiManager.state == .noProvider {
                    showAISetup = true
                }
            }
        }
    }
}

struct ScanView: View {
    @State private var pixelBuffer: CVPixelBuffer?
    @State private var detectedFood: String = "Align food & Tap Capture"
    @State private var nutritionInfo: NutritionInfo?
    @State private var detectedResults: [InferenceResult] = []
    @State private var isScanning = true
    @State private var showResult = false
    @State private var isProcessing = false
    @State private var capturedImage: UIImage?
    @State private var isBarcodeMode = false

    @StateObject private var barcodeScanner = BarcodeScanner()

    private let modelHandler: ModelDataHandler? = {
        let fileInfo = FileInfo(name: "model", fileExtension: "tflite")
        return ModelDataHandler(modelFileInfo: fileInfo)
    }()

    private let nutritionManager = NutritionManager.shared

    var body: some View {
        ZStack {
            // Camera Layer
            CameraView(pixelBuffer: $pixelBuffer)
                .edgesIgnoringSafeArea(.all)

            // Overlay Layer
            VStack {
                // Mode Toggle at the top
                if !showResult {
                    HStack(spacing: 0) {
                        Button(action: { withAnimation { isBarcodeMode = false } }) {
                            Text("AI Scan")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(isBarcodeMode ? Color.clear : Color.green)
                                .foregroundColor(isBarcodeMode ? .white.opacity(0.7) : .white)
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("AI Scan mode")
                        .accessibilityHint("Switches to AI food recognition mode")
                        .accessibilityAddTraits(!isBarcodeMode ? .isSelected : [])
                        Button(action: { withAnimation { isBarcodeMode = true } }) {
                            Text("Barcode")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 20)
                                .background(isBarcodeMode ? Color.green : Color.clear)
                                .foregroundColor(isBarcodeMode ? .white : .white.opacity(0.7))
                                .cornerRadius(8)
                        }
                        .accessibilityLabel("Barcode mode")
                        .accessibilityHint("Switches to barcode scanning mode")
                        .accessibilityAddTraits(isBarcodeMode ? .isSelected : [])
                    }
                    .background(Color.black.opacity(0.6))
                    .cornerRadius(10)
                    .padding(.top, 60)
                }

                Spacer()

                if showResult {
                    if !detectedResults.isEmpty {
                        // Multi-Object View (Local Model)
                        MultiObjectResultView(
                            image: capturedImage,
                            results: detectedResults,
                            onLog: { loggedItems in
                                resetScan()
                            },
                            onCancel: {
                                resetScan()
                            }
                        )
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                    } else if let info = nutritionInfo {
                        // Single Result View (Cloud/Barcode/Legacy)
                        ResultView(
                            image: capturedImage,
                            dishName: detectedFood,
                            nutrition: info,
                            onLog: {
                                nutritionManager.logFood(dish: detectedFood, info: info)
                                AnalyticsService.logFoodLogged(dish: detectedFood, calories: Int(info.calories) ?? 0)
                                resetScan()
                            },
                            onCancel: {
                                resetScan()
                            }
                        )
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                    }
                } else {
                    // Capture Controls
                    VStack(spacing: 20) {
                        Text(detectedFood)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)

                        if isBarcodeMode {
                            // Barcode Capture Button
                            Button(action: {
                                captureAndScanBarcode()
                            }) {
                                VStack {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.orange, lineWidth: 5)
                                            .frame(width: 80, height: 80)

                                        if isProcessing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .accessibilityLabel("Scanning barcode")
                                        } else {
                                            Image(systemName: "barcode.viewfinder")
                                                .font(.system(size: 32))
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    Text("Scan Barcode")
                                        .font(.caption)
                                        .foregroundColor(.white)
                                        .bold()
                                }
                            }
                            .disabled(isProcessing)
                            .accessibilityLabel(isProcessing ? "Scanning barcode" : "Scan Barcode")
                            .accessibilityHint("Captures the current view and scans for a barcode")
                            .padding(.bottom, 30)
                        } else {
                            HStack(spacing: 40) {
                                // Local Capture
                                Button(action: {
                                    captureAndAnalyze(useCloud: false)
                                }) {
                                    ZStack {
                                        Circle()
                                            .stroke(Color.white, lineWidth: 5)
                                            .frame(width: 80, height: 80)

                                        if isProcessing {
                                            ProgressView()
                                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                                .accessibilityLabel("Processing image")
                                        } else {
                                            Circle()
                                                .fill(Color.white)
                                                .frame(width: 70, height: 70)
                                        }
                                    }
                                }
                                .disabled(isProcessing)
                                .accessibilityLabel(isProcessing ? "Processing" : "Local Detect")
                                .accessibilityHint("Captures photo and analyzes food using the on-device model")

                                // Cloud Capture
                                Button(action: {
                                    captureAndAnalyze(useCloud: true)
                                }) {
                                    VStack {
                                        Image(systemName: "sparkles")
                                            .font(.title)
                                            .foregroundColor(.white)
                                            .padding()
                                            .background(Color.purple)
                                            .clipShape(Circle())
                                        Text("AI Analyze")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                            .bold()
                                    }
                                }
                                .disabled(isProcessing)
                                .accessibilityLabel("Cloud Scan")
                                .accessibilityHint("Captures photo and analyzes food using cloud AI")
                            }
                            .padding(.bottom, 30)
                        }
                    }
                }
            }
        }
    }

    func captureAndScanBarcode() {
        guard let buffer = pixelBuffer, !isProcessing else { return }

        isProcessing = true
        detectedFood = "Scanning barcode..."

        // Capture image from buffer
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: ciImage.extent) else {
            isProcessing = false
            detectedFood = "Failed to capture image."
            return
        }
        let image = UIImage(cgImage: cgImage)
        self.capturedImage = image

        // Run barcode detection
        barcodeScanner.scanBarcode(from: image)

        // Observe the result
        Task {
            // Give the Vision framework a moment to process
            try? await Task.sleep(nanoseconds: 500_000_000)

            await MainActor.run {
                guard let code = barcodeScanner.lastBarcode else {
                    self.detectedFood = "No barcode found. Try again."
                    self.isProcessing = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        if !showResult {
                            self.detectedFood = "Align food & Tap Capture"
                        }
                    }
                    return
                }

                self.detectedFood = "Barcode: \(code) - Looking up..."

                Task {
                    do {
                        if let (name, info) = try await barcodeScanner.lookupBarcode(code) {
                            await MainActor.run {
                                self.detectedFood = name
                                self.nutritionInfo = info
                                self.showResult = true
                                self.isProcessing = false
                                AnalyticsService.logFoodScanned(dish: name, source: "barcode")
                            }
                        } else {
                            await MainActor.run {
                                self.detectedFood = "Product not found for barcode: \(code)"
                                self.isProcessing = false
                                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                                    if !showResult {
                                        self.detectedFood = "Align food & Tap Capture"
                                    }
                                }
                            }
                        }
                    } catch {
                        print("Barcode lookup error: \(error)")
                        await MainActor.run {
                            self.detectedFood = "Lookup failed. Try again."
                            self.isProcessing = false
                        }
                    }
                }
            }
        }
    }

    func captureAndAnalyze(useCloud: Bool) {
        guard let buffer = pixelBuffer, !isProcessing else { return }

        isProcessing = true
        detectedFood = useCloud ? "Asking AI..." : "Analyzing..."

        // Capture image for UI
        let ciImage = CIImage(cvPixelBuffer: buffer)
        let context = CIContext()
        if let cgImage = context.createCGImage(ciImage, from: ciImage.extent) {
            self.capturedImage = UIImage(cgImage: cgImage)
        }

        if useCloud {
            // Cloud Flow
            guard let img = self.capturedImage else { return }
            Task {
                do {
                    let (name, info) = try await APIService.shared.analyzeFood(image: img)
                    DispatchQueue.main.async {
                        self.detectedFood = name
                        self.nutritionInfo = info
                        self.showResult = true
                        self.isProcessing = false
                        AnalyticsService.logFoodScanned(dish: name, source: "cloud")
                    }
                } catch {
                    print("API Error: \(error)")
                    DispatchQueue.main.async {
                        self.detectedFood = "AI Failed. Try again."
                        self.isProcessing = false
                    }
                }
            }
        } else {
            // Local Flow
            DispatchQueue.global(qos: .userInitiated).async {
                let results = modelHandler?.runModel(onFrame: buffer)

                DispatchQueue.main.async {
                    self.isProcessing = false

                    if let smartResults = results, !smartResults.isEmpty {
                        self.detectedResults = smartResults
                        self.detectedFood = "\(smartResults.count) items detected"
                        for item in smartResults {
                            AnalyticsService.logFoodScanned(dish: item.label, source: "local")
                        }
                        withAnimation {
                            self.showResult = true
                            self.isScanning = false
                        }
                    } else {
                        self.detectedFood = "No food detected."
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if !showResult {
                                self.detectedFood = "Align food & Tap Capture"
                            }
                        }
                    }
                }
            }
        }
    }

    func resetScan() {
        withAnimation {
            self.showResult = false
            self.isScanning = true
            self.detectedFood = "Align food & Tap Capture"
            self.nutritionInfo = nil
            self.detectedResults = []
            self.capturedImage = nil
        }
    }
}


