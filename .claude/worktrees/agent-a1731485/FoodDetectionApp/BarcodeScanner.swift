import Foundation
import Vision
import UIKit
import Combine

class BarcodeScanner: ObservableObject {
    @Published var lastBarcode: String?

    // MARK: - Barcode Detection

    func scanBarcode(from image: UIImage) {
        guard let cgImage = image.cgImage else {
            DispatchQueue.main.async { self.lastBarcode = nil }
            return
        }

        let request = VNDetectBarcodesRequest { [weak self] request, error in
            guard error == nil,
                  let results = request.results as? [VNBarcodeObservation] else {
                DispatchQueue.main.async { self?.lastBarcode = nil }
                return
            }

            // Look for EAN-13 or UPC-A barcodes
            let barcode = results.first(where: { (obs: VNBarcodeObservation) -> Bool in
                obs.symbology == VNBarcodeSymbology.ean13 || obs.symbology == VNBarcodeSymbology.ean8 || obs.symbology == VNBarcodeSymbology.upce
            })

            DispatchQueue.main.async {
                self?.lastBarcode = barcode?.payloadStringValue
            }
        }

        // Limit to the barcode symbologies we care about
        request.symbologies = [VNBarcodeSymbology.ean13, VNBarcodeSymbology.ean8, VNBarcodeSymbology.upce]

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        DispatchQueue.global(qos: .userInitiated).async {
            try? handler.perform([request])
        }
    }

    // MARK: - Open Food Facts Lookup

    func lookupBarcode(_ code: String) async throws -> (name: String, info: NutritionInfo)? {
        guard let url = URL(string: "https://world.openfoodfacts.org/api/v0/product/\(code).json") else {
            return nil
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let root = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return nil
        }

        // Check if the product was found
        guard let status = root["status"] as? Int, status == 1 else {
            return nil
        }

        guard let product = root["product"] as? [String: Any] else {
            return nil
        }

        let productName = product["product_name"] as? String ?? "Unknown Product"

        guard let nutriments = product["nutriments"] as? [String: Any] else {
            return nil
        }

        let calories = nutrimentValue(nutriments, key: "energy-kcal_100g")
        let carbs = nutrimentValue(nutriments, key: "carbohydrates_100g")
        let protein = nutrimentValue(nutriments, key: "proteins_100g")
        let fat = nutrimentValue(nutriments, key: "fat_100g")

        let info = NutritionInfo(
            calories: calories,
            recipe: "Scanned from barcode. Consider pairing with vegetables for a balanced meal.",
            carbs: carbs,
            protein: protein,
            fats: fat,
            source: "Open Food Facts",
            micros: nil
        )

        return (name: productName, info: info)
    }

    // MARK: - Helpers

    private func nutrimentValue(_ nutriments: [String: Any], key: String) -> String {
        if let val = nutriments[key] as? Double {
            return String(format: "%.1f", val)
        }
        if let val = nutriments[key] as? Int {
            return String(val)
        }
        if let val = nutriments[key] as? String {
            return val
        }
        return "0"
    }
}
