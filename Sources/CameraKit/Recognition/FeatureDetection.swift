import CoreImage
import Vision

actor FeatureDetection {
    // MARK: Rectangle Detection
    static func rectangle(in image: sending CIImage) async -> [CGPoint]? {
        var request = DetectRectanglesRequest()
        request.minimumAspectRatio = 0.5
        request.maximumAspectRatio = 0.8
        request.minimumSize = 0.3
        request.maximumObservations = 1

        guard let first = try? await request.perform(on: image).first else { return nil }
        return [first.topLeft, first.topRight, first.bottomRight, first.bottomLeft].map { CGPoint(x: $0.x, y: $0.y) }
    }

    // MARK: Text Detection
    static func text(in image: sending CIImage) async -> [RecognizedTextObservation] {
        var request = RecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = false
        return (try? await request.perform(on: image)) ?? []
    }
}
