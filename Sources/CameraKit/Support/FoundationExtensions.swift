//
//  FoundationExtensions.swift
//  CameraKit
//
//  Created by Marcos del Castillo Camacho on 17/2/25.
//

import Foundation
import ImageIO
import UniformTypeIdentifiers

extension URL {
    /// A unique output location to write a movie.
    public static var movieFileURL: URL {
        URL.temporaryDirectory.appending(component: UUID().uuidString).appendingPathExtension(for: .quickTimeMovie)
    }
}

extension Data {
    /// Returns the preferred file extension for the image format detected from the data content.
    var imageFileExtension: String? {
        guard let source = CGImageSourceCreateWithData(self as CFData, nil),
              let uti = CGImageSourceGetType(source),
              let type = UTType(uti as String) else { return nil }
        return type.preferredFilenameExtension
    }
}
