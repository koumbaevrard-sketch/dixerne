import Foundation
import UIKit
import Vision

/// Extraction de texte depuis une image via l'OCR on-device d'Apple (Vision framework).
/// 100 % hors ligne : aucun pixel ne quitte l'appareil.
enum VisionService {

    static func recognizeText(in image: UIImage) async throws -> String {
        guard let cgImage = image.cgImage else {
            throw VisionError.invalidImage
        }

        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let text = observations
                    .compactMap { $0.topCandidates(1).first?.string }
                    .joined(separator: "\n")
                continuation.resume(returning: text)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = [
                "fr-FR", "en-US", "es-ES", "de-DE", "it-IT",
                "pt-PT", "nl-NL", "zh-Hans", "ja-JP", "ar-SA",
            ]

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    enum VisionError: LocalizedError {
        case invalidImage

        var errorDescription: String? {
            switch self {
            case .invalidImage: "Image invalide ou illisible."
            }
        }
    }
}
