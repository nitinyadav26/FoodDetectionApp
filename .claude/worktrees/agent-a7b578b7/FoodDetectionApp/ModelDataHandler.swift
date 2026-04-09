import Foundation
import TensorFlowLite
import CoreImage
import UIKit
import Accelerate

struct InferenceResult {
    let rect: CGRect
    let confidence: Float
    let label: String
}

class ModelDataHandler {
    
    // MARK: - Properties
    let threadCount: Int
    let threadCountLimit = 10
    let threshold: Float = 0.4 // Confidence threshold
    
    private var interpreter: Interpreter
    private var labels: [String] = []
    
    // Model parameters (YOLOv8/11 specific)
    let inputWidth = 640
    let inputHeight = 640
    let inputChannels = 3
    
    // MARK: - Initialization
    init?(modelFileInfo: FileInfo, threadCount: Int = 1) {
        self.threadCount = threadCount
        
        guard let modelPath = Bundle.main.path(
            forResource: modelFileInfo.name,
            ofType: modelFileInfo.fileExtension
        ) else {
            print("Failed to load the model file with name: \(modelFileInfo.name).")
            return nil
        }
        
        var options = Interpreter.Options()
        options.threadCount = threadCount
        
        do {
            interpreter = try Interpreter(modelPath: modelPath, options: options)
            try interpreter.allocateTensors()
        } catch let error {
            print("Failed to create the interpreter with error: \(error.localizedDescription)")
            return nil
        }
        
        // Load labels dynamically from nutrition_data.json
        loadLabels()
    }
    
    private func loadLabels() {
        // Hardcoded class order from the YOLO model (extracted via backend.py model.names)
        self.labels = [
            "Indianbread", "Rasgulla", "Biryani", "Uttapam", "Paneer", "Poha", "Khichdi", "Omelette",
            "Plainrice", "Dalmakhani", "Rajma", "Poori", "Chole", "Dal", "Sambhar", "Papad",
            "Gulabjamun", "Idli", "Vada", "Dosa", "Jalebi", "Samosa", "Paobhaji", "Dhokla",
            "Barfi", "Fishcurry", "Momos", "Kheer", "Kachori", "Vadapav", "Rasmalai", "Kalachana",
            "Chaat", "Saag", "Dumaloo", "Thupka", "Khandvi", "Kabab", "Thepla", "Rasam",
            "Appam", "Gatte", "Kadhipakora", "Ghewar", "Aloomatter", "Prawns", "Sandwich", "Dahipuri",
            "Haleem", "Mutton", "Aloogobi", "Eggbhurji", "Lemonrice", "Bhindimasala", "Matarmushroom", "Gajarkahalwa",
            "Motichoorladoo", "Ragiroti", "Chickentikka", "Tandoorichicken", "Lauki", "chanamasala", "bainganbharta", "karelabharta",
            "crabcurry", "kathiroll", "gujiya", "malpua", "mysorepak", "kaddu", "rabri", "chenapoda",
            "kulfi", "pakora", "boondi", "phirni", "tilkut", "Chilla", "Handvo", "Basundi",
            "Litti chokha", "kothimbirvadi", "Soya chaap", "sabudanakhichdi", "shevbhaji", "jeerarice", "Chettinad chicken", "masortenga",
            "Chikki", "moongdalhalwa", "avial", "dalbati", "malaikofta", "chickenchangezi", "pesarattu", "patishapta",
            "chingrimalaicurry", "pootharekulu", "imarti", "upma"
        ]
        print("Loaded \(labels.count) labels from YOLO model class order")
    }
    
    // MARK: - Inference
    func runModel(onFrame pixelBuffer: CVPixelBuffer) -> [InferenceResult]? {
        let sourcePixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        assert(sourcePixelFormat == kCVPixelFormatType_32BGRA ||
               sourcePixelFormat == kCVPixelFormatType_32ARGB)
        

        
        guard let thumbnailPixelBuffer = pixelBuffer.centerThumbnail(ofSize: CGSize(width: inputWidth, height: inputHeight)) else {
            return nil
        }
        
        let outputTensor: Tensor
        do {
            guard let inputData = rgbDataFromBuffer(
                thumbnailPixelBuffer,
                byteCount: inputWidth * inputHeight * inputChannels,
                isModelQuantized: false
            ) else {
                print("Failed to convert input buffer")
                return nil
            }
            
            try interpreter.copy(inputData, toInputAt: 0)
            try interpreter.invoke()
            outputTensor = try interpreter.output(at: 0)
        } catch let error {
            print("Failed to invoke the interpreter with error: \(error.localizedDescription)")
            return nil
        }
        
        return processYoloOutput(tensor: outputTensor)
    }
    
    // MARK: - Helper Methods
    
    private func rgbDataFromBuffer(
        _ buffer: CVPixelBuffer,
        byteCount: Int,
        isModelQuantized: Bool
    ) -> Data? {
        CVPixelBufferLockBaseAddress(buffer, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(buffer, .readOnly) }
        
        guard let sourceData = CVPixelBufferGetBaseAddress(buffer) else { return nil }
        
        let width = CVPixelBufferGetWidth(buffer)
        let height = CVPixelBufferGetHeight(buffer)
        let sourceRowBytes = CVPixelBufferGetBytesPerRow(buffer)
        let destinationChannelCount = 3
        let destinationBytesPerRow = destinationChannelCount * width
        
        var sourceBuffer = vImage_Buffer(data: sourceData, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: sourceRowBytes)
        
        guard let destinationData = malloc(height * destinationBytesPerRow) else {
            print("Error: out of memory")
            return nil
        }
        
        defer {
            free(UnsafeMutableRawPointer(mutating: destinationData))
        }
        
        var destinationBuffer = vImage_Buffer(data: destinationData, height: vImagePixelCount(height), width: vImagePixelCount(width), rowBytes: destinationBytesPerRow)
        
        if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32BGRA){
            vImageConvert_BGRA8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        } else if (CVPixelBufferGetPixelFormatType(buffer) == kCVPixelFormatType_32ARGB) {
            vImageConvert_ARGB8888toRGB888(&sourceBuffer, &destinationBuffer, UInt32(kvImageNoFlags))
        }
        
        let byteData = Data(bytes: destinationBuffer.data, count: destinationBuffer.rowBytes * height)
        
        if isModelQuantized { return byteData }
        
        // Normalize to Float 0-1
        let bytes = Array<UInt8>(unsafeData: byteData)!
        var floats = [Float]()
        for i in 0..<bytes.count {
            floats.append(Float(bytes[i]) / 255.0)
        }
        return Data(copyingBufferOf: floats)
    }
    
    // MARK: - Safe Array Access
    private func getFloat(from array: [Float], index: Int) -> Float {
        if index < array.count {
            return array[index]
        }
        return 0.0
    }

    private func processYoloOutput(tensor: Tensor) -> [InferenceResult] {
        let outputData = tensor.data
        let outputFloats = outputData.toArray(type: Float.self)
        
        // YOLOv8/11 Output Shape is typically: [1, 4 + num_classes, 8400]
        // Dimensions: 4 (x,y,w,h) + numClasses
        // This is TRANSPOSED compared to standard TFLite usually.
        // We access it as rows of [4+classes] for each of the 8400 anchors.
        
        // However, YOLO export default is often [1, dimensions, 8400] (channels first)
        // Let's assume standard [1, 4+num_classes, 8400] based on previous code structure
        
        let numClasses = labels.count
        let dimensions = 4 + numClasses // e.g., 4 + 72 = 76
        let numAnchors = 8400
        
        guard outputFloats.count >= dimensions * numAnchors else {
            print("Output tensor size mismatch")
            return []
        }
        
        var candidates: [InferenceResult] = []
        
        // Accessing [1, dimensions, numAnchors] (Channels First)
        // Index = (channel * numAnchors) + anchor
        
        for anchorIdx in 0..<numAnchors {
            // 1. Find the best class score for this anchor
            var maxClassScore: Float = 0.0
            var maxClassIndex = -1
            
            // Optimization: Iterate classes to find max
            for classIdx in 0..<numClasses {
                // Class scores start at index 4
                let classChannel = 4 + classIdx
                let scoreIdx = (classChannel * numAnchors) + anchorIdx
                let score = getFloat(from: outputFloats, index: scoreIdx)
                
                if score > maxClassScore {
                    maxClassScore = score
                    maxClassIndex = classIdx
                }
            }
            
            // 2. Filter by threshold
            if maxClassScore > threshold {
                 // 3. Extract Bounding Box
                // Channels 0,1,2,3 correspond to cx, cy, w, h
                let cx = getFloat(from: outputFloats, index: (0 * numAnchors) + anchorIdx)
                let cy = getFloat(from: outputFloats, index: (1 * numAnchors) + anchorIdx)
                let w  = getFloat(from: outputFloats, index: (2 * numAnchors) + anchorIdx)
                let h  = getFloat(from: outputFloats, index: (3 * numAnchors) + anchorIdx)
                
                // Convert center-xywh to top-left-xywh (normalized 0-1 if model output is such, usually pixels in YOLO)
                // YOLO raw output is usually relative to input size (640x640)
                
                let x = cx - (w / 2)
                let y = cy - (h / 2)
                
                let rect = CGRect(x: Double(x), y: Double(y), width: Double(w), height: Double(h))
                
                let candidate = InferenceResult(
                    rect: rect,
                    confidence: maxClassScore,
                    label: labels[maxClassIndex]
                )
                candidates.append(candidate)
            }
        }
        
        // 4. Input candidates to NMS
        return nonMaxSuppression(boxes: candidates, iouThreshold: 0.45, limit: 10)
    }
    
    // MARK: - NMS
    private func nonMaxSuppression(boxes: [InferenceResult], iouThreshold: Float, limit: Int) -> [InferenceResult] {
        // Sort by confidence (descending)
        let sortedBoxes = boxes.sorted { $0.confidence > $1.confidence }
        var selected: [InferenceResult] = []
        var activeBoxes = sortedBoxes
        
        while !activeBoxes.isEmpty {
            let first = activeBoxes.removeFirst()
            selected.append(first)
            
            if selected.count >= limit { break }
            
            // Remove boxes that have high overlap (IoU) with the current 'first'
            activeBoxes = activeBoxes.filter { box in
                let iou = intersectionOverUnion(box.rect, first.rect)
                return iou < Double(iouThreshold)
            }
        }
        
        return selected
    }
    
    private func intersectionOverUnion(_ rect1: CGRect, _ rect2: CGRect) -> Double {
        let intersection = rect1.intersection(rect2)
        if intersection.isNull { return 0.0 }
        
        let intersectionArea = intersection.width * intersection.height
        let unionArea = (rect1.width * rect1.height) + (rect2.width * rect2.height) - intersectionArea
        
        if unionArea <= 0 { return 0.0 }
        return Double(intersectionArea / unionArea)
    }
}

// Helper for file info
struct FileInfo {
    let name: String
    let fileExtension: String
}

// Helper for CVPixelBuffer resizing
extension CVPixelBuffer {
    func centerThumbnail(ofSize size: CGSize) -> CVPixelBuffer? {
        let imageWidth = CVPixelBufferGetWidth(self)
        let imageHeight = CVPixelBufferGetHeight(self)
        let pixelBufferType = CVPixelBufferGetPixelFormatType(self)
        
        assert(pixelBufferType == kCVPixelFormatType_32BGRA ||
               pixelBufferType == kCVPixelFormatType_32ARGB)
        
        let inputImageRowBytes = CVPixelBufferGetBytesPerRow(self)
        let imageChannels = 4
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        defer { CVPixelBufferUnlockBaseAddress(self, .readOnly) }
        
        guard let inputBaseAddress = CVPixelBufferGetBaseAddress(self) else {
            return nil
        }
        
        var inputVImageBuffer = vImage_Buffer(
            data: UnsafeMutableRawPointer(mutating: inputBaseAddress),
            height: vImagePixelCount(imageHeight),
            width: vImagePixelCount(imageWidth),
            rowBytes: inputImageRowBytes
        )
        
        let thumbnailRowBytes = Int(size.width) * imageChannels
        guard let thumbnailBytes = malloc(Int(size.height) * thumbnailRowBytes) else {
            return nil
        }
        
        var thumbnailVImageBuffer = vImage_Buffer(
            data: thumbnailBytes,
            height: vImagePixelCount(size.height),
            width: vImagePixelCount(size.width),
            rowBytes: thumbnailRowBytes
        )
        
        let scaleError = vImageScale_ARGB8888(
            &inputVImageBuffer,
            &thumbnailVImageBuffer,
            nil,
            vImage_Flags(kvImageHighQualityResampling)
        )
        
        guard scaleError == kvImageNoError else {
            free(thumbnailBytes)
            return nil
        }
        
        var thumbnailPixelBuffer: CVPixelBuffer?
        let status = CVPixelBufferCreateWithBytes(
            nil,
            Int(size.width),
            Int(size.height),
            pixelBufferType,
            thumbnailBytes,
            thumbnailRowBytes,
            { releaseContext, baseAddress in
                if let baseAddress = baseAddress {
                    free(UnsafeMutableRawPointer(mutating: baseAddress))
                }
            },
            nil,
            nil,
            &thumbnailPixelBuffer
        )
        
        guard status == kCVReturnSuccess else {
            free(thumbnailBytes)
            return nil
        }
        
        return thumbnailPixelBuffer
    }
}

extension Data {
    func toArray<T>(type: T.Type) -> [T] {
        return self.withUnsafeBytes {
            Array($0.bindMemory(to: T.self))
        }
    }
}
