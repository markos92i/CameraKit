import CoreImage
import Vision

actor FeatureDetection {
    // Reuse request instances to avoid repeated setup and internal pipeline allocation.
    private static let rectangleRequest: DetectRectanglesRequest = {
        var request = DetectRectanglesRequest()
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 0.8
        request.minimumSize = 0.3
        request.maximumObservations = 1
        return request
    }()

    private static let textRequest: RecognizeTextRequest = {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        return request
    }()

    // MARK: Rectangle Detection
    static func rectangle(in image: sending CIImage) async -> [CGPoint]? {
        guard let first = try? await rectangleRequest.perform(on: image).first else { return nil }
        return [first.topLeft, first.topRight, first.bottomRight, first.bottomLeft].map { CGPoint(x: $0.x, y: $0.y) }
    }

    // MARK: Text Detection
    static func text(in image: sending CIImage) async -> [RecognizedTextObservation] {
        (try? await textRequest.perform(on: image)) ?? []
    }
}
