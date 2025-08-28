import CoreML
import Vision
import UIKit

final class CarClassifierService {
    static let shared = CarClassifierService()

    private let vnModel: VNCoreMLModel

    private init() {
        // Load generated model (from your CarClassifier.mlpackage/.mlmodel)
        // If your generated class has a throwing init, try? is fine here with a hard fail if missing.
        let coreModel: CarClassifier
        do {
            coreModel = try CarClassifier()
        } catch {
            fatalError("Failed to load CarClassifier: \(error)")
        }

        guard let vn = try? VNCoreMLModel(for: coreModel.model) else {
            fatalError("Could not create VNCoreMLModel")
        }
        self.vnModel = vn
    }

    enum PredictionError: Error { case failed, noOutput }

    /// Returns (index, confidence 0..1) for the top class.
    func classify(image: UIImage) -> Result<(Int, Float), PredictionError> {
        guard let cg = image.cgImage else { return .failure(.failed) }

        let request = VNCoreMLRequest(model: vnModel)
        request.imageCropAndScaleOption = .centerCrop

        let handler = VNImageRequestHandler(cgImage: cg,
                                            orientation: image.cgImagePropertyOrientation,
                                            options: [:])
        do {
            try handler.perform([request])
        } catch {
            return .failure(.failed)
        }

        guard let obs = request.results?.first as? VNCoreMLFeatureValueObservation,
              let scores = obs.featureValue.multiArrayValue else {
            return .failure(.noOutput)
        }

        // Argmax over Float32 scores
        let count = scores.count
        var maxIdx = 0
        var maxVal = Float(scores[0].floatValue)
        for i in 1..<count {
            let v = Float(scores[i].floatValue)
            if v > maxVal {
                maxVal = v
                maxIdx = i
            }
        }

        // Softmax confidence (optional, but nicer to display)
        var sum: Float = 0
        for i in 0..<count {
            sum += expf(Float(scores[i].floatValue))
        }
        let confidence = expf(maxVal) / max(1e-9, sum)

        return .success((maxIdx, confidence))
    }
}

// Orientation helper for Vision
extension UIImage {
    var cgImagePropertyOrientation: CGImagePropertyOrientation {
        switch imageOrientation {
        case .up: return .up
        case .down: return .down
        case .left: return .left
        case .right: return .right
        case .upMirrored: return .upMirrored
        case .downMirrored: return .downMirrored
        case .leftMirrored: return .leftMirrored
        case .rightMirrored: return .rightMirrored
        @unknown default: return .up
        }
    }

    // Normalize orientation (so .cgImage pixels are upright)
    func fixedOrientation() -> UIImage {
        if imageOrientation == .up { return self }
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(in: CGRect(origin: .zero, size: size))
        let normalized = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return normalized ?? self
    }
}

