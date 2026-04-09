import SwiftUI

struct SettingsView: View {
    @AppStorage("appTheme") private var appTheme: String = "system"
    @AppStorage("usesMetric") private var usesMetric: Bool = true
    @ObservedObject var nutritionManager = NutritionManager.shared
    @State private var showDeleteConfirmation = false
    @State private var showExportSheet = false
    @State private var exportURL: URL?

    var body: some View {
        Form {
            Section(header: Text("Appearance")) {
                Picker("Theme", selection: $appTheme) {
                    Text("System").tag("system")
                    Text("Light").tag("light")
                    Text("Dark").tag("dark")
                }
            }

            Section(header: Text("Units")) {
                Picker("Measurement", selection: $usesMetric) {
                    Text("Metric (kg, cm)").tag(true)
                    Text("Imperial (lb, in)").tag(false)
                }
            }

            Section(header: Text("Legal")) {
                Link("Privacy Policy", destination: URL(string: "https://foodsense-app.web.app/privacy-policy")!)
                Link("Terms of Service", destination: URL(string: "https://foodsense-app.web.app/terms-of-service")!)
            }

            Section(header: Text("Data")) {
                Button("Export My Data") {
                    exportData()
                }

                Button("Delete All Data", role: .destructive) {
                    showDeleteConfirmation = true
                }
            }

            Section(header: Text("About")) {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                        .foregroundColor(.secondary)
                }
            }
        }
        .navigationTitle("Settings")
        .alert("Delete All Data?", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) {}
            Button("Delete Everything", role: .destructive) {
                nutritionManager.deleteAllData()
            }
        } message: {
            Text("This will permanently delete all your food logs, stats, and preferences. This cannot be undone.")
        }
        .sheet(isPresented: $showExportSheet) {
            if let url = exportURL {
                ShareSheet(activityItems: [url])
            }
        }
    }

    private func exportData() {
        let data = nutritionManager.exportAllData()
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("foodsense_export.json")
        try? data.write(to: tempURL)
        exportURL = tempURL
        showExportSheet = true
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
