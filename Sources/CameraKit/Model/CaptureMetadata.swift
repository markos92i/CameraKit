//
//  CaptureMetadata.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 3/7/25.
//

import SwiftUI

public struct CaptureMetadata: Identifiable, Sendable, Equatable {
    public let id: UUID
    public let type: CaptureType
    public let description: String
    public let coordinates: [CGPoint]

    let image: CIImage

    init(id: UUID = UUID(), type: CaptureType, image: CIImage, description: String = "", coordinates: [CGPoint]) {
        self.id = id
        self.type = type
        self.image = image
        self.description = description
        self.coordinates = coordinates
    }

    /// Creates a CaptureMetadata with a stable ID derived from the description text.
    init(stableID text: String, type: CaptureType, image: CIImage, coordinates: [CGPoint]) {
        // Generate a deterministic UUID from the text hash so SwiftUI can track identity across frames
        var hasher = Hasher()
        hasher.combine(text)
        let hash = hasher.finalize()
        let bytes = withUnsafeBytes(of: hash) { Array($0) }
        let uuid = UUID(uuid: (
            bytes[0], bytes[1], bytes[2], bytes[3],
            bytes[4], bytes[5], bytes[6], bytes[7],
            0, 0, 0, 0, 0, 0, 0, 0
        ))
        self.id = uuid
        self.type = type
        self.image = image
        self.description = text
        self.coordinates = coordinates
    }

    public enum CaptureType: Sendable, Equatable {
        case rectangle
        case text
        case face
    }
}

extension CaptureMetadata {
    public var crop: CIImage { image.perspective(points: CGPointUtils.scale(coordinates, to: image.extent.size)) }
    
    /// Writes the cropped image to a file and returns its URL.
    public func writeCrop(compressionQuality: CGFloat = 0.9) -> URL? {
        let context = CIContext()
        guard let cgImage = context.createCGImage(crop, from: crop.extent) else { return nil }
        let uiImage = UIImage(cgImage: cgImage)
        guard let data = uiImage.jpegData(compressionQuality: compressionQuality) else { return nil }
        let timestamp = Date.now.formatted(
            .verbatim("\(year: .padded(4))\(month: .twoDigits)\(day: .twoDigits)_\(hour: .twoDigits(clock: .twentyFourHour, hourCycle: .zeroBased))\(minute: .twoDigits)\(second: .twoDigits)", timeZone: .current, calendar: .current)
        )
        let url = URL.documentsDirectory.appending(path: "cropped_\(timestamp).jpg")
        guard (try? data.write(to: url)) != nil else { return nil }
        return url
    }
    
    var flippedPoints: [CGPoint] {
        CGPointUtils.flipVertically(CGPointUtils.scale(coordinates, to: image.extent.size), extent: image.extent)
    }
    var radius: CGFloat {
        switch type {
        case .rectangle: 10
        case .text: 2
        case .face: 20
        }
    }
    var lineWidth: CGFloat {
        switch type {
        case .rectangle: 2
        case .text: 1
        case .face: 2
        }
    }
}
